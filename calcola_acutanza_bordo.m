function acutanza = calcola_acutanza_bordo(img, centro, raggio)
    theta = 0; % Analizziamo un angolo fisso (es. orizzontale)
    distanze = (raggio-10):(raggio+10);
    x = centro(1) + distanze * cos(theta);
    y = centro(2) + distanze * sin(theta);
    
    profilo = interp2(double(img), x, y, 'linear');
    
    % Contrasto locale: (Max-Min)/(Max+Min) 
    Imax = max(profilo);
    Imin = min(profilo);
    contrasto = (Imax - Imin) / (Imax + Imin);
    
    % Acutanza come pendenza media del bordo (derivata rispetto allo spazio)
    pendenza = mean(abs(diff(profilo)));
    acutanza = contrasto * pendenza; 
end