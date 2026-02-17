function [c_pupil, r_pupil, c_iris, r_iris] = segmentazione_daugman(img_roi_denoised)
%% SEGMENTAZIONE DAUGMAN (Operatore Integro-Differenziale)
%  Massimizza: max | d/dr * G * Integral(I(x,y)) |
%  Non richiede toolbox esterni oltre a Image Processing standard.

    % Convertiamo in double per precisione matematica
    I = double(img_roi_denoised);
    [rows, cols] = size(I);
    
    %% 1. SEGMENTAZIONE PUPILLA
    % Strategia: La pupilla è molto scura. Per velocizzare Daugman,
    % restringiamo l'area di ricerca del centro usando una stima preliminare
    % (simile a come Hough usa soglie, qui usiamo binarizzazione rapida).
    
    % Stima grossolana del centro
    soglia_est = min(I(:)) + (max(I(:)) - min(I(:))) * 0.3; % 30% intensità
    bin_mask = I < soglia_est;
    props = regionprops(bin_mask, 'Centroid', 'MajorAxisLength');
    
    if ~isempty(props)
        % Prendi la regione più grande (probabile pupilla)
        [~, idx] = max([props.MajorAxisLength]);
        start_x = round(props(idx).Centroid(1));
        start_y = round(props(idx).Centroid(2));
    else
        start_x = round(cols/2);
        start_y = round(rows/2);
    end
    
    % Definizione Area di Ricerca Daugman (Pupilla)
    search_r = 10; % Cerca +/- 10 pixel attorno alla stima
    rng_x = max(1, start_x-search_r) : min(cols, start_x+search_r);
    rng_y = max(1, start_y-search_r) : min(rows, start_y+search_r);
    
    % Range Raggi Pupilla (adattato dal tuo codice)
    rng_r = 10:35; 
    
    % Esecuzione Operatore Daugman (Pupilla)
    % Cerca transizione Scura -> Chiara (gradiente positivo)
    [c_pupil, r_pupil] = daugman_core(I, rng_x, rng_y, rng_r, 'Pupil');


    %% 2. SEGMENTAZIONE IRIDE
    % L'iride condivide quasi lo stesso centro della pupilla.
    % Restringiamo la ricerca al centro trovato precedentemente.
    
    % Definizione Area di Ricerca Daugman (Iride)
    search_r_iris = 5; % Piccola tolleranza dal centro pupilla
    rng_x_i = round(c_pupil(1)-search_r_iris) : round(c_pupil(1)+search_r_iris);
    rng_y_i = round(c_pupil(2)-search_r_iris) : round(c_pupil(2)+search_r_iris);
    
    % Range Raggi Iride (basato sulla pupilla trovata)
    % Tipicamente l'iride è da 1.5x a 4.5x la pupilla
    r_min_i = round(r_pupil * 1.6);
    r_max_i = round(r_pupil * 4.2);
    
    % Controllo limiti immagine (per non uscire fuori)
    max_radius_possible = min([rows/2, cols/2]) - 2;
    r_max_i = min(r_max_i, max_radius_possible);
    
    rng_r_i = r_min_i:2:r_max_i; % Step 2 per velocità
    
    % Esecuzione Operatore Daugman (Iride)
    % Cerca transizione Iride(Scura) -> Sclera(Chiara) (gradiente positivo)
    [c_iris, r_iris] = daugman_core(I, rng_x_i, rng_y_i, rng_r_i, 'Iris');

end

%% FUNZIONE MATEMATICA CORE (Ottimizzata)
function [best_c, best_r] = daugman_core(img, x_range, y_range, r_range, ~)
    
    [H, W] = size(img);
    max_gradient = -inf;
    best_c = [mean(x_range), mean(y_range)];
    best_r = mean(r_range);
    
    % Discretizzazione dell'integrale circolare
    % Usiamo meno punti per velocità, ma sufficienti per precisione
    n_angles = 60; 
    theta = linspace(0, 2*pi, n_angles);
    
    % Per l'iride, spesso le palpebre coprono sopra e sotto.
    % Usiamo solo i settori laterali per l'iride per migliorare la robustezza?
    % Per ora usiamo tutto il cerchio per coerenza con Hough classico, 
    % ma rimuoviamo i bordi estremi.
    
    cos_t = cos(theta);
    sin_t = sin(theta);
    
    % Pre-allocazione per velocità
    intensities = zeros(1, length(r_range));
    
    % Ciclo ottimizzato sui centri (Grid Search)
    for cx = x_range
        for cy = y_range
            
            % Check rapido bordi ROI
            if cx < 1 || cx > W || cy < 1 || cy > H
                continue; 
            end

            % Calcolo Integrale per ogni raggio
            for k = 1:length(r_range)
                r = r_range(k);
                
                % Calcolo coordinate cerchio
                x_circ = round(cx + r * cos_t);
                y_circ = round(cy + r * sin_t);
                
                % Filtro punti validi (dentro l'immagine)
                valid_idx = (x_circ >= 1 & x_circ <= W & y_circ >= 1 & y_circ <= H);
                
                % Se il cerchio esce troppo dall'immagine, penalizzalo o saltalo
                if sum(valid_idx) < (n_angles * 0.8) % Richiede almeno 80% del cerchio
                    intensities(k) = NaN;
                else
                    % Estrazione valori pixel (Indici lineari per velocità)
                    ind = sub2ind([H, W], y_circ(valid_idx), x_circ(valid_idx));
                    intensities(k) = mean(img(ind));
                end
            end
            
            % --- MATEMATICA DI DAUGMAN ---
            % Calcoliamo la derivata parziale rispetto al raggio.
            % diff(I) calcola I(r+1) - I(r).
            
            % Gestione NaN (se il cerchio usciva dai bordi)
            if any(isnan(intensities))
                grads = zeros(size(intensities)); % Ignora questo centro
            else
                % Gradiente discreto
                grads = diff(intensities);
                
                % Smoothing del gradiente (essenziale per rumore)
                % Simula la G (Gaussiana) nella formula di Daugman
                grads = conv(grads, [1, 2, 1], 'same'); 
            end
            
            % Cerchiamo il picco
            % Pupilla->Iride e Iride->Sclera sono transizioni Scuro->Chiaro
            % Quindi cerchiamo il massimo positivo.
            [val, idx_r] = max(grads);
            
            if val > max_gradient
                max_gradient = val;
                best_c = [cx, cy];
                % idx_r punta all'indice di diff, che è raggio intermedio
                best_r = r_range(idx_r); 
            end
            
        end
    end
end