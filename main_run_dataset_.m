%% SEGMENTAZIONE, NORMALIZZAZIONE ED ENCODING SU TUTTO IL DATASET
clc; clear; close all;

% Scelta del metodo
choice = questdlg('Quale metodo di segmentazione vuoi usare?', ...
	'Selezione Metodo', ...
	'Hough', 'Daugman', 'Annulla', 'Hough');

% Gestione della risposta
switch choice
    case 'Hough'
        SCELTA_METODO = 1;
    case 'Daugman'
        SCELTA_METODO = 2;
    otherwise
     
        disp('Operazione annullata dall''utente.');
        return; 
end

% Dimensioni iride normalizzata
h_out = 64; 
w_out = 512;  

% Selezione cartella Dataset
folderPath = uigetdir(pwd, 'Seleziona Cartella Dataset');
if folderPath == 0, error('Annullato.'); end

files = dir(fullfile(folderPath, '*.jpg')); 
nFiles = length(files);
if nFiles == 0, error('Nessuna immagine trovata.'); end

% Crea cartelle Output
if SCELTA_METODO == 1
    nome_metodo = 'Hough';
else
    nome_metodo = 'Daugman';
end

out_dir_img = fullfile(folderPath, ['Risultati_visivi_' nome_metodo]);
out_dir_data = fullfile(folderPath, ['Dati_' nome_metodo]);

if ~exist(out_dir_img, 'dir'), mkdir(out_dir_img); end
if ~exist(out_dir_data, 'dir'), mkdir(out_dir_data); end

% Ciclo elaborazione
hWait = waitbar(0, 'Elaborazione...');

for k = 1:nFiles
    fname = files(k).name;
    fullPath = fullfile(folderPath, fname);

        waitbar(k/nFiles, hWait, sprintf('%d/%d: %s', k, nFiles));
        
% Filtraggio canale Rosso
img_rgb = imread(fullPath);
img_red = img_rgb(:,:,1); 

% Correzione riflessi ed enhancement
se_tophat = strel('disk', 20);
img_tophat = imtophat(img_red, se_tophat);
mask_riflessi = img_tophat > 35;
img_smooth = regionfill(img_red, mask_riflessi);
img_gamma = imadjust(img_smooth, [0 1], [0.2 1], 1);
img_enhanced = adapthisteq(img_gamma,'ClipLimit', 0.05 ,'Distribution', 'uniform', 'NumTiles', [6 6]);
img_denoised = medfilt2(img_enhanced, [7 7]);

%% CALCOLO ROI

[rows, cols] = size(img_red);

% Se l'immagine è larga meno di 400px, assumiamo sia CASIA e usiamo tutta
% l'immagine, altrimenti assumiamo sia UBIRIS e usiamo la ROI.

if cols < 400 
    % CASIA
    c_min = 1; 
    r_min = 1;
    box_width = cols; 
    box_height = rows;
    
    img_roi_denoised = img_denoised; % Passiamo l'immagine intera
    
else
    % UBIRIS
    y_center = rows/2;
    x_center = cols/2;
    
    box_width = 180;
    box_height = 160; 

    c_min = round(x_center - box_width/2); 
    r_min = round(y_center - box_height/2); 
    c_max = min(cols, c_min + box_width - 1);
    r_max = min(rows, r_min + box_height - 1);
    
    img_roi_denoised = img_denoised(r_min:r_max, c_min:c_max);
end
        
%% CHIAMATA FUNZIONI

        if SCELTA_METODO == 1
            % Chiama la funzione Hough 
            [c_pupil, r_pupil, c_iris, r_iris] = segmentazione_hough(img_roi_denoised); 
        else
            % Chiama la funzione Active
            [c_pupil, r_pupil, c_iris, r_iris] = segmentazione_daugman(img_roi_denoised);
        end

% Calcolo SNR sulla ROI (Valuta rumore sensore) 
metrica_snr = calcola_snr(img_roi_denoised);

% Conversione coordinate        
c_pupil_global = c_pupil + [c_min-1, r_min-1];
c_iris_global = c_iris + [c_min-1, r_min-1];

% Chiamata funzioni normalizzazione ed encoding
[img_norm] = normalizza_iride(img_red, c_pupil_global, r_pupil, c_iris_global, r_iris, h_out, w_out);
iris_code = encode_iris(img_norm);

%% VISUALIZZAZIONE

% Segmentazione
f = figure('visible', 'off'); 
subplot(3,1,1); imshow(img_red); hold on; title(fname, 'Interpreter', 'none');
rectangle('Position', [c_min, r_min, box_width, box_height], 'EdgeColor', 'g');
viscircles(c_pupil_global, r_pupil, 'Color', 'r', 'LineWidth', 1);
viscircles(c_iris_global, r_iris, 'Color', 'c', 'LineWidth', 2);
plot([c_pupil_global(1), c_iris_global(1)+r_iris], [c_pupil_global(2), c_iris_global(2)], 'g', 'LineStyle','--'); % Raggio (theta = 0)
plot(c_pupil_global(1), c_pupil_global(2), 'r+', 'MarkerSize', 8);
plot(c_iris_global(1), c_iris_global(2), 'bx', 'MarkerSize', 8);
% Normalizzazione
subplot(3,1,2); imshow(img_norm); title({'Iride Normalizzata', ''});
xlabel('Angolo \theta (0 \rightarrow 2\pi)');
ylabel('Raggio (Pupilla \rightarrow Iride)');
axis on; 
% Encoding 
subplot(3,1,3); imshow(iris_code); title({'Encoding Iride', ''});
ylabel('Bit (Reale / Immaginario)');
xlabel('Fase');
axis on; 
 
% Salvataggio immagini e dati (iris_code, c_pupil_global, r_pupil, c_iris_global, r_iris)
saveas(f, fullfile(out_dir_img, ['Report_' fname '.jpg']));
[~, nameNoExt, ~] = fileparts(fname);
matFileName = fullfile(out_dir_data, [nameNoExt '.mat']);
save(matFileName, 'iris_code', 'c_pupil_global', 'r_pupil', 'c_iris_global', 'r_iris', 'fname', 'metrica_snr');
close(f);
       
end

close(hWait);
msgbox('Operazione completata!');