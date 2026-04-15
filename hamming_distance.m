function score = hamming_distance(template1, template2)

%% MATCHING TRA DUE IRIS_CODE CON SHIFTING (Compensazione Rotazione)
% Configurazione shifting per spostamenti della testa
shifts = -8:8; 

% Inizializziamo il punteggio migliore con il valore 
% peggiore possibile (1.0 = totalmente diversi).
best_score = 1.0;

% 3. Normalizza
total_bits = numel(template1);

% Facciamo il confronto per ogni shift e teniamo il 
% risultato migliore
for s = shifts
    % Ruota il secondo template di 's' colonne
    % [0, s]: 0 shift verticale, s shift orizzontale
    template2_shifted = circshift(template2, [0, s]);
    
    % restituisce 1 se i bit sono diversi, 0 se uguali
    diff_map = xor(template1, template2_shifted);
    num_diff = sum(diff_map(:));
    
    current_score = num_diff / total_bits;
    
    % Selezione del migliore
    if current_score < best_score
        best_score = current_score;
    end
end
score = best_score;
end