function snr_val = calcola_snr(img_roi)
    % Converte in double
    img_d = double(img_roi);
    
    % Identifica un'area di "segnale" (es. porzione dell'iride) 
    % e un'area di "rumore" (es. un angolo scuro della ROI)
    segnale_medio = mean(img_d(:));
    
    % Deviazione standard come stima del rumore totale
    rumore_std = std(img_d(:));
    
    if rumore_std == 0
        snr_val = Inf;
    else
        % Rapporto Segnale-Rumore 
        snr_val = segnale_medio / rumore_std;
    end
end