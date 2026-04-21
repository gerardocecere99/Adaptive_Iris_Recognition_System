function [c_pupil, r_pupil, c_iris, r_iris] = segmentazione_daugman_(img_roi_denoised)

%% SEGMENTAZIONE DAUGMAN — Operatore Integro-Differenziale
I = double(img_roi_denoised);
[rows, cols] = size(I);

%% PARAMETRI ADATTATIVI (CASIA / UBIRIS)
if cols > 200           % CASIA
    search_window = 40;
    pupil_rad_min = 25;  pupil_rad_max = 80;
    iris_mult_min = 1.8; iris_mult_max = 3.5;
else                    % UBIRIS
    search_window = 10;
    pupil_rad_min = 10;  pupil_rad_max = 35;
    iris_mult_min = 1.5; iris_mult_max = 4.2;
end

%% 1. STIMA CENTRO PUPILLA — SOGLIATURA
soglia = prctile(I(:), 30);
mask   = I < soglia;
[ys, xs] = find(mask);
if ~isempty(xs)
    start_x = round(mean(xs));
    start_y = round(mean(ys));
else
    start_x = round(cols/2);
    start_y = round(rows/2);
end

%% 2. DAUGMAN — PUPILLA
rng_x = max(1, start_x-search_window) : min(cols, start_x+search_window);
rng_y = max(1, start_y-search_window) : min(rows, start_y+search_window);
rng_r = pupil_rad_min : 2 : pupil_rad_max;
[c_pupil, r_pupil] = daugman_core(I, rng_x, rng_y, rng_r);

%% 3. DAUGMAN — IRIDE
sr      = 5;
rng_x_i = max(1, round(c_pupil(1)-sr)) : min(cols, round(c_pupil(1)+sr));
rng_y_i = max(1, round(c_pupil(2)-sr)) : min(rows, round(c_pupil(2)+sr));
r_min_i = round(r_pupil * iris_mult_min);
r_max_i = min(round(r_pupil * iris_mult_max), min(rows,cols)/2 - 2);
if r_min_i >= r_max_i, r_max_i = r_min_i + 15; end
rng_r_i = r_min_i : 2 : r_max_i;
[c_iris, r_iris] = daugman_core(I, rng_x_i, rng_y_i, rng_r_i);
end

% ---------------------------------------------------------------
function [best_c, best_r] = daugman_core(I, x_range, y_range, r_range)
[H, W] = size(I);
if isempty(x_range), x_range = round(W/2); end
if isempty(y_range), y_range = round(H/2); end
best_c    = [mean(x_range), mean(y_range)];
best_r    = mean(r_range);
max_score = -inf;

% [ADDED] Kernel gaussiano 1D per smoothing di mean_I prima della derivata
sigma_g  = 1.5;                          % deviazione standard (regolabile)
half_k   = ceil(3 * sigma_g);
kx       = -half_k : half_k;
gauss_k  = exp(-kx.^2 / (2*sigma_g^2));
gauss_k  = gauss_k / sum(gauss_k);       % normalizzazione   


theta = linspace(0, 2*pi*(1 - 1/72), 72);
cos_t = cos(theta);
sin_t = sin(theta);

Nr     = numel(r_range);
mean_I = zeros(1, Nr);

for cx = x_range
    for cy = y_range
        if cx < 1 || cx > W || cy < 1 || cy > H, continue; end

        % Integrale di linea: media delle intensità lungo la circonferenza
        for k = 1:Nr
            r  = r_range(k);
            xi = round(cx + r * cos_t);
            yi = round(cy + r * sin_t);
            valid = xi >= 1 & xi <= W & yi >= 1 & yi <= H;
            if mean(valid) < 0.8
                mean_I(k) = NaN;
            else
                idx       = sub2ind([H W], yi(valid), xi(valid));
                mean_I(k) = mean(I(idx));
            end
        end

        if any(isnan(mean_I)), continue; end

        % Smoothing gaussiano su mean_I (convoluzione 1D)
        mean_I_smooth = conv(mean_I, gauss_k, 'same');

        % Derivata discreta (diff) sul segnale smoothato
        dI_dr = abs(diff(mean_I_smooth)); 

        [val, idx_r] = max(dI_dr);
        if val > max_score
            max_score = val;
            best_c    = [cx, cy];
            best_r    = r_range(idx_r);
        end
    end
end
end
