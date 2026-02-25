%% MATCHING ANALYSIS: Valutazione Finale del Sistema
clc; clear; close all;

% Seleziona la cartella dove hai salvato i file .mat 
dataFolder = uigetdir(pwd, 'Seleziona la cartella Dati');
if dataFolder == 0, return; end

files = dir(fullfile(dataFolder, '*.mat'));
nFiles = length(files);

if nFiles < 2
    error('Servono almeno 2 file .mat per fare un confronto!');
end

% Caricamento dati
templates = cell(nFiles, 1);
ids = zeros(nFiles, 1); 
names = cell(nFiles, 1);

for k = 1:nFiles
    loaded = load(fullfile(dataFolder, files(k).name));
    templates{k} = loaded.iris_code;
    names{k} = loaded.fname;

    fname = files(k).name;
    
    % Usa espressione regolare per trovare cifre consecutive
    numStr = regexp(fname, '\d+', 'match'); 
    
    if ~isempty(numStr)
        % Il primo numero trovato è l'ID della persona
        ids(k) = str2double(numStr{1});
    else
        % Se non trova numeri, assegna un ID univoco fittizio o NaN
        warning(['Impossibile estrarre ID da: ' fname]);
        ids(k) = NaN; 
    end 
end

% Matching
scores_positivi = [];  % Confronti Stessa Persona 
scores_negativi = [];  % Confronti Persone Diverse 
hWait = waitbar(0, 'Matching in corso...');

% Confronto dei file
for i = 1:nFiles
    for j = i+1:nFiles % evita di confrontare A con A o (A,B) e poi (B,A)
        
        % Calcola Hamming Distance
        hd = hamming_distance(templates{i}, templates{j});
        
        % Verifica Identità
        if ids(i) == ids(j)
            % Stessa persona
            scores_positivi = [scores_positivi; hd];
        else
            % Persone diverse
            scores_negativi = [scores_negativi; hd];
        end
        
    end
    waitbar(i/nFiles, hWait);
end
close(hWait);

% Visualizzazione grafica
figure('Name', 'Analisi Prestazioni Biometriche');

% Istogrammi sovrapposti
hold on;
h1 = histogram(scores_positivi, 20, 'Normalization', 'probability', 'FaceColor', 'g', 'FaceAlpha', 0.6);
h2 = histogram(scores_negativi, 20, 'Normalization', 'probability', 'FaceColor', 'r', 'FaceAlpha', 0.6);

title('Distribuzione Hamming Distance');
xlabel('Hamming Distance');
ylabel('Probabilità');
legend([h1, h2], {'Positivi (Stessa Persona)', 'Negativi (Persone Diverse)'});
grid on;

% Analisi statistica
media_positivi = mean(scores_positivi);
media_negativi = mean(scores_negativi);

fprintf('RISULTATI');
fprintf('Confronti Positivi totali: %d\n', length(scores_positivi));
fprintf('Confronti Negativi totali: %d\n', length(scores_negativi));
fprintf('Media HD Positivi: %.4f (Ideale: ~0.1 - 0.2)\n', media_positivi);
fprintf('Media HD Negativi: %.4f (Ideale: ~0.5)\n', media_negativi);

if media_positivi < media_negativi
    msgbox('Le distribuzioni sono separate.');
else
    msgbox('Il sistema non distingue bene le persone.');
end