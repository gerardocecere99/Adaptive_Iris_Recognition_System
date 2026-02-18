function [c_pupil, r_pupil, c_iris, r_iris] = segmentazione_daugman(img_roi_denoised)
%% SEGMENTAZIONE DAUGMAN (Operatore Integro-Differenziale)

% Convertiamo in double per precisione matematica
I = double(img_roi_denoised);
[rows, cols] = size(I);
    
%% PARAMETRI ADATTIVI (CASIA / UBIRIS) 
% Se l'immagine è > 200px, assumiamo sia CASIA, se è <= 200px, è UBIRIS.
% Rimozione riflessi
se_fill = strel('disk', 10); 
I_clean = imclose(I, se_fill);
    
    if cols > 200
        % Parametri CASIA
        search_window = 40;     % Cerchiamo il centro in un'area ampia (+/- 40px)
        pupil_rad_min = 25;     % Pupilla minima molto più grande
        pupil_rad_max = 80;     % Pupilla massima enorme
        iris_mult_min = 1.8;    % L'iride inizia a 1.8x la pupilla
        iris_mult_max = 3.5;    % L'iride finisce a 3.5x la pupilla
    else
        % Parametri UBIRIS
        search_window = 10;     % Ricerca locale stretta (+/- 10px)
        pupil_rad_min = 10;     % Pupilla standard piccola
        pupil_rad_max = 35;     
        iris_mult_min = 1.5;    % Standard UBIRIS
        iris_mult_max = 4.2;
    end
    
    %% 1. SEGMENTAZIONE PUPILLA
    % Stima grossolana del centro tramite binarizzazione
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
    
    % Definizione Area di Ricerca Daugman (Usa search_window adattiva)
    rng_x = max(1, start_x-search_window) : min(cols, start_x+search_window);
    rng_y = max(1, start_y-search_window) : min(rows, start_y+search_window);
    
    % Range Raggi Pupilla (Usa i parametri adattivi)
    rng_r = pupil_rad_min:2:pupil_rad_max; 
    
    % Esecuzione Operatore Daugman (Pupilla)
    [c_pupil, r_pupil] = daugman_core(I_clean, rng_x, rng_y, rng_r, 'Pupil');


    %% 2. SEGMENTAZIONE IRIDE
    % L'iride condivide il centro. Restringiamo la ricerca al centro trovato.
    search_r_iris = 5; 
    rng_x_i = round(c_pupil(1)-search_r_iris) : round(c_pupil(1)+search_r_iris);
    rng_y_i = round(c_pupil(2)-search_r_iris) : round(c_pupil(2)+search_r_iris);
    
    % Range Raggi Iride (Calcolati con i moltiplicatori adattivi)
    r_min_i = round(r_pupil * iris_mult_min);
    r_max_i = round(r_pupil * iris_mult_max);
    
    % Controllo limiti immagine (per non uscire fuori)
    max_radius_possible = min([rows/2, cols/2]) - 2;
    r_max_i = min(r_max_i, max_radius_possible);
    
    % Correzione di sicurezza: se r_min > r_max, forza un range valido
    if r_min_i >= r_max_i
        r_max_i = r_min_i + 15; 
    end
    
    rng_r_i = r_min_i:2:r_max_i; 
    
    % Esecuzione Operatore Daugman (Iride)
    [c_iris, r_iris] = daugman_core(I_clean, rng_x_i, rng_y_i, rng_r_i, 'Iris');

end

%% FUNZIONE MATEMATICA 
function [best_c, best_r] = daugman_core(img, x_range, y_range, r_range, ~)
    
    [H, W] = size(img);
    max_gradient = -inf;
    
    % Default di sicurezza
    if isempty(x_range), x_range = round(W/2); end
    if isempty(y_range), y_range = round(H/2); end
    
    best_c = [mean(x_range), mean(y_range)];
    best_r = mean(r_range);
    
    n_angles = 60; 
    theta = linspace(0, 2*pi, n_angles);
    cos_t = cos(theta);
    sin_t = sin(theta);
    
    intensities = zeros(1, length(r_range));
    
    % Ciclo sui centri
    for cx = x_range
        for cy = y_range
            
            if cx < 1 || cx > W || cy < 1 || cy > H, continue; end

            for k = 1:length(r_range)
                r = r_range(k);
                x_circ = round(cx + r * cos_t);
                y_circ = round(cy + r * sin_t);
                
                valid_idx = (x_circ >= 1 & x_circ <= W & y_circ >= 1 & y_circ <= H);
                
                if sum(valid_idx) < (n_angles * 0.8) 
                    intensities(k) = NaN;
                else
                    ind = sub2ind([H, W], y_circ(valid_idx), x_circ(valid_idx));
                    intensities(k) = mean(img(ind));
                end
            end
            
            if any(isnan(intensities))
                grads = zeros(size(intensities));
            else
                grads = diff(intensities);
                grads = conv(grads, [1, 2, 1], 'same'); 
            end
            
            [val, idx_r] = max(grads);
            
            if val > max_gradient
                max_gradient = val;
                best_c = [cx, cy];
                best_r = r_range(idx_r); 
            end
        end
    end
end