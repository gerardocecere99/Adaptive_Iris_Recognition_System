function [c_pupil, r_pupil, c_iris, r_iris] = segmentazione_hough(img_roi_denoised)

    %% INIZIALIZZAZIONE ADATTIVA E FALLBACK
    [rows, cols] = size(img_roi_denoised);
    center_default = [cols/2, rows/2];
    
    % Parametri dinamici
    % Se l'immagine in ingresso è larga > 200px, stiamo lavorando su CASIA (320px).
    % Se è larga <= 200px, stiamo lavorando su UBIRIS (180px).

    if cols > 200
        IS_CASIA = true;
        % Parametri per occhi più grandi (CASIA)
        Rp_range = [30 80];        % Pupilla più grande
        Sens_pupil = 0.99;         % CASIA è molto netto, possiamo alzare la sensibilità
        R_iris_mult_min = 1.8;     % Moltiplicatori per iride
        R_iris_mult_max = 3.5;
    else
        IS_CASIA = false;
        % Parametri per occhi più piccoli (UBIRIS)
        Rp_range = [8 25];
        Sens_pupil = 0.96;
        R_iris_mult_min = 1.5;
        R_iris_mult_max = 4.5;
    end

    % Valori di Default
    c_pupil = center_default; 
    r_pupil = Rp_range(1) + 10; 
    c_iris = center_default;
    r_iris = r_pupil * 2.5;

    %% SEGMENTAZIONE PUPILLA    
    img_pupil_in = img_roi_denoised; 

    % Preprocessing standard
    img_no_ref = ordfilt2(img_pupil_in, 1, true(7));
    se_bg = strel('disk', 45); 
    img_bg = imclose(img_no_ref, se_bg);
    img_diff = imsubtract(img_bg, img_no_ref);

    % Maschera Spotlight
    [h_roi, w_roi] = size(img_diff);
    [xx, yy] = meshgrid(1:w_roi, 1:h_roi);
    center_x = w_roi/2; center_y = h_roi/2;
    sigma = w_roi / 3.0; 
    spotlight = exp(-((xx - center_x).^2 + (yy - center_y).^2) / (2 * sigma^2));
    img_weighted = uint8(double(img_diff) .* spotlight);

    % Binarizzazione / Clamping
    img_calc = img_weighted;
    img_calc(img_calc > 100) = 100;
    max_val = max(img_calc(:));
    soglia = double(max_val) * 0.30; 
    img_pupil = img_weighted;
    img_pupil(img_pupil < soglia) = 0;
    img_pupil = imgaussfilt(img_pupil, 2); 

    % Hough Transform Pupilla (Usa Rp_range dinamico)
    [centers, radii, metric] = imfindcircles(img_pupil, Rp_range, ...
        'ObjectPolarity', 'bright', ... 
        'Sensitivity', Sens_pupil, ... 
        'EdgeThreshold', 0.05, ...
        'Method', 'TwoStage');

    if ~isempty(centers)
        c_roi_center = [w_roi/2, h_roi/2];
        dists = sqrt(sum((centers - c_roi_center).^2, 2));
        
        % Tolleranza distanza: su CASIA (immagine grande) possiamo tollerare di più
        if IS_CASIA, max_dist = 40; else, max_dist = 20; end
        
        valid = dists < max_dist;
        
        if any(valid)
            scores = (metric(valid) * 100) - (dists(valid) * 2);
            [~, best_sub_idx] = max(scores);
            valid_indices = find(valid);
            best_idx = valid_indices(best_sub_idx);
            
            c_pupil = centers(best_idx, :);
            r_pupil = radii(best_idx);
        end
    end

    %% SEGMENTAZIONE IRIDE
    % Range dinamici basati sulla pupilla trovata
    R_iris_min = round(r_pupil * R_iris_mult_min); 
    R_iris_max = round(r_pupil * R_iris_mult_max);
    
    % Check di sicurezza per non crashare imfindcircles 
    if R_iris_max <= R_iris_min, R_iris_max = R_iris_min + 20; end
   
    img_iris = img_roi_denoised; 
    img_iris = imgaussfilt(img_iris, 2.5);

    % Hough Iride
    [centers_iris, radii_iris, metric_iris] = imfindcircles(img_iris, ...
    [R_iris_min R_iris_max], ...
    'ObjectPolarity', 'dark', ... 
    'Sensitivity', 0.98, ...      
    'EdgeThreshold', 0.02, ...    
    'Method', 'TwoStage');
    
    if ~isempty(centers_iris)
        dists_iris = sqrt(sum((centers_iris - c_pupil).^2, 2));
        valid = dists_iris < 25; 
        
        if any(valid)
            c_valid = centers_iris(valid, :);
            r_valid = radii_iris(valid, :);
            m_valid = metric_iris(valid, :);
            d_valid = dists_iris(valid, :);
            
            scores = m_valid - (d_valid / 20);
            [~, best_idx] = max(scores);
            
            c_iris = c_valid(best_idx, :);
            r_iris = r_valid(best_idx);
        end
    end
end