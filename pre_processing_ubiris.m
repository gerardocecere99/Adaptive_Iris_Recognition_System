clc; clear; close all;

%% STEP 1: CARICAMENTO IMMAGINE E PRE PROCESSING

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

% Correzione riflessi ed enhancement
se_tophat = strel('disk', 20);
img_tophat = imtophat(img_red, se_tophat);
mask_riflessi = img_tophat > 35;
img_smooth = regionfill(img_red, mask_riflessi);
img_gamma = imadjust(img_smooth, [0 1], [0.2 1], 1);
img_enhanced = adapthisteq(img_gamma,'ClipLimit', 0.05 ,'Distribution', 'uniform', 'NumTiles', [6 6]);
img_denoised = medfilt2(img_enhanced, [7 7]);

% Visualizzazione grafica
figure('Name', 'Pre processing');
subplot(1,4,1); imshow(img_rgb); title('Immagine originale');
subplot(1,4,2); imshow(img_red); title('Canale Rosso Filtrato');
subplot(1,4,3); imshow(img_smooth); title('Riflessi rimossi');
subplot(1,4,4); imshow(img_denoised); title('Immagine pre processata');


