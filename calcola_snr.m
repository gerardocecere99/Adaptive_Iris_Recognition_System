function snr_db = calcola_snr(img_roi)
    % Stima SNR basata su patch omogenea
    % Misuriamo il rumore solo in un angolo dove non c'è l'iride.

    img_d = double(img_roi);
    [rows, cols] = size(img_d);
    
    % SEGNALE: luminosità media di tutto l'occhio
    segnale = mean(img_d(:));
    
    % RUMORE: lo misuriamo in un quadratino 20x20 pixel in alto a sinistra
    % Assumiamo che lì ci sia una zona piatta
    box_size = 20;
    
    % Controllo di sicurezza: se l'immagine è piccolissima
    if rows < box_size || cols < box_size
        box_size = min(rows, cols);
    end
    
    % Estraiamo il quadratino (patch)
    patch_rumore = img_d(1:box_size, 1:box_size);
    
    % Calcoliamo la variazione SOLO lì dentro.
    %La deviazione standard è davvero "grana" fotografica.
    rumore = std(patch_rumore(:));
    
    % Calcolo SNR
    if rumore == 0
        snr_db = 100; % Caso ideale (rumore zero)
    else
        snr_db = 20 * log10(segnale / rumore);
    end
end