clc; clear; close all;

%% CARICAMENTO IMMAGINE E PRE PROCESSING

% Definizione manuale del file
image = 'subdataset_ubiris_100\C1_S1_I1.tiff'; 

% Lettura immagine
try
    img_rgb = imread(image);
catch
    error('File non trovato! Controlla il percorso del file.');
end

% Filtraggio canale Rosso
img_red = img_rgb(:,:,1); 

% Rimozione Riflessi 
se_tophat = strel('disk', 20);
img_tophat = imtophat(img_red, se_tophat);
mask_riflessi = img_tophat > 35;
img_smooth = regionfill(img_red, mask_riflessi);

% CLAHE (Contrast Limited Adaptive Histogram Equalization)
img_enhanced = adapthisteq(img_smooth, 'ClipLimit', 0.05, 'Distribution', 'uniform', 'NumTiles', [6 6]);

% Filtro mediano
img_denoised = medfilt2(img_enhanced, [3 3]); 

% Visualizzazione grafica
figure('Name', 'Pre processing');
subplot(1,4,1); imshow(img_rgb); title('Immagine originale');
subplot(1,4,2); imshow(img_red); title('Canale Rosso Filtrato');
subplot(1,4,3); imshow(img_smooth); title('Riflessi rimossi');
subplot(1,4,4); imshow(img_denoised); title('Immagine pre processata');


