clc; clear; close all;
pkg load image

% Dimensiones de la imagen procesada
img_width = 32;
img_height = 32;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Creacion de datos para comparar

% Leer la imagen
Im = imread('cameraman.tif');
I = Im(50:150, 50:150, :);

% Redimensionar la imagen a 32x32 píxeles
I_resized = imresize(I, [32, 32]);

% Convertir la imagen a escala de grises si es necesario
if size(I_resized, 3) == 3
    I_gray = rgb2gray(I_resized);
else
    I_gray = I_resized;
end

% Convertir la imagen a uint8 para trabajar con valores de 8 bits
I_gray = uint8(I_gray);

% Ampliar la imagen en los bordes con ceros
I_padded = padarray(I_gray, [1 1], 0, 'both');

% Mostrar la imagen redimensionada y ampliada
figure;
imshow(I_padded, []);
title('Imagen Redimensionada a 32x32 con Bordes Ampliados');

% Guardar los datos de los píxeles en un archivo
fileID = fopen('pixeles.txt', 'w');
for i = 1:size(I_padded, 1)
    for j = 1:size(I_padded, 2)
        fprintf(fileID, '%08s\n', dec2bin(I_padded(i, j), 8));
    end
end
fclose(fileID);
disp('Archivo pixeles.txt generado correctamente.');

% Definir los filtros de Sobel
Gx = [0 0 0; -1 0 1; 0 0 0];
Gy = [0 -1 0; 0 0 0; 0 1 0];

% Aplicar los filtros de Sobel con la opción 'same'
gradX = conv2(double(I_gray), Gx, 'same');
gradY = conv2(double(I_gray), Gy, 'same');

% Calcular a y b
a = max(abs(gradX), abs(gradY));
b = min(abs(gradX), abs(gradY));

% Calcular la magnitud usando la fórmula proporcionada
magnitudes = max(0.875 * a + 0.5 * b, a);

% Parámetros del HOG
cellSize = 8; % Tamaño de la celda
numBins = 9;  % Número de bins en el histograma
tanTheta = tand(linspace(0, 180, numBins + 1)); % Límites de los bines

% Inicializar el histograma
[h, w] = size(I_gray);
hog = zeros(h/cellSize, w/cellSize, numBins);

% Calcular el histograma para cada celda
for i = 1:cellSize:h
    for j = 1:cellSize:w
        cellMagnitudes = magnitudes(i:i+cellSize-1, j:j+cellSize-1);
        cellGradX = gradX(i:i+cellSize-1, j:j+cellSize-1);
        cellGradY = gradY(i:i+cellSize-1, j:j+cellSize-1);
        cellHistogram = zeros(1, numBins);
        for x = 1:cellSize
            for y = 1:cellSize
                gx = cellGradX(x, y);
                gy = cellGradY(x, y);
                mag = cellMagnitudes(x, y);
                for bin = 1:numBins
                    if gx * tanTheta(bin) < gy && gy < gx * tanTheta(bin + 1)
                        cellHistogram(bin) = cellHistogram(bin) + mag;
                        break;
                    end
                end
            end
        end
        hog(floor(i/cellSize)+1, floor(j/cellSize)+1, :) = cellHistogram;
    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Evaluacion de gradX
gradx_vivado=zeros(img_width,img_height);
fileID = fopen('gradx.txt', 'r');  % Abre el archivo para lectura
if fileID == -1
    error('No se pudo abrir el archivo');
end

% Define el número de líneas a leer
numLines = 32*32;

% Inicializa la variable A
A = cell(numLines, 1);  % Usamos una celda para almacenar las líneas binarias

% Lee las 1024 líneas
for i = 1:1021
    A{i} = strtrim(fgetl(fileID));  % Lee una línea, elimina los espacios en blanco
    if length(A{i}) ~= 10
        error('Una de las líneas no tiene 9 caracteres. Verifica el archivo.');
    end
end

% Ahora convertimos cada línea (que es una cadena binaria) a un entero con signo
A_signed = zeros(numLines, 1);  % Prealocamos el vector de enteros con signo
cont=2;

for i = 1:1021
    % Convertimos cada línea de caracteres binarios a un número entero
    bin_str = A{i};  % Obtiene la cadena binaria (de 9 bits)

    % Si el primer bit es 1, es un número negativo (complemento a dos)
    if bin_str(1) == '1'
        % Convertir la cadena binaria a número entero sin signo
        unsigned_value = bin2dec(bin_str);
        % Convertir al valor con signo (complemento a dos)
        signed_value = unsigned_value - 2^10;  % 9 bits, restamos 2^9 para obtener el valor negativo
    else
        % Si el primer bit es 0, el número es positivo
        signed_value = bin2dec(bin_str);
    end

    % Guardamos el valor con signo en el arreglo
    A_signed(cont) = signed_value;
    cont++;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Evaluacion GradY
grady_vivado=zeros(img_width,img_height);

fileID = fopen('grady.txt', 'r');  % Abre el archivo para lectura
if fileID == -1
    error('No se pudo abrir el archivo');
end



% Inicializa la variable B
B = cell(numLines, 1);  % Usamos una celda para almacenar las líneas binarias

% Lee las 1024 líneas
for i = 1:1021
    B{i} = strtrim(fgetl(fileID));  % Lee una línea, elimina los espacios en blanco
    if length(B{i}) ~= 10
        error('Una de las líneas no tiene 9 caracteres. Verifica el archivo.');
    end
end

% Ahora convertimos cada línea (que es una cadena binaria) a un entero con signo
B_signed = zeros(numLines, 1);  % Prealocamos el vector de enteros con signo
cont=2;

for i = 1:1021
    % Convertimos cada línea de caracteres binarios a un número entero
    bin_str = B{i};  % Obtiene la cadena binaria (de 9 bits)

    % Si el primer bit es 1, es un número negativo (complemento a dos)
    if bin_str(1) == '1'
        % Convertir la cadena binaria a número entero sin signo
        unsigned_value = bin2dec(bin_str);
        % Convertir al valor con signo (complemento a dos)
        signed_value = unsigned_value - 2^10;  % 9 bits, restamos 2^9 para obtener el valor negativo
    else
        % Si el primer bit es 0, el número es positivo
        signed_value = bin2dec(bin_str);
    end

    % Guardamos el valor con signo en el arreglo
    B_signed(cont) = signed_value;
    cont++;
end

% Muestra los resultados
%disp(A_signed);

fclose(fileID);  % Cierra el archivo




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Proceso de comparacion de valores

cont=1;

for i=1:img_width
  for j=1:img_height
    gradx_vivado(i,j)=A_signed(cont);
    cont++;
  end
end

cont=1;

for i=1:img_width
  for j=1:img_height
    grady_vivado(i,j)=B_signed(cont);
    cont++;
  end
end


% Comparar los valores
diff = gradX - gradx_vivado;

% Mostrar métricas de comparación
max_diff = max(abs(diff(:)));
mean_diff = mean(abs(diff(:)));

fprintf("Máxima diferencia: %d\n", max_diff);
fprintf("Diferencia media: %f\n", mean_diff);

% Visualizar diferencias
figure;
imagesc(abs(diff));
colorbar;
title("Diferencias absolutas entre gradx y gradx_vivado");
xlabel("Columnas");
ylabel("Filas");

% Verificar tolerancia
tolerance = 1;
if all(abs(diff(:)) <= tolerance)
    fprintf("Todos los valores están dentro del margen de tolerancia (%d).\n", tolerance);
else
    fprintf("Hay valores fuera del margen de tolerancia (%d).\n", tolerance);
end



% Comparar los valores
diff = gradY - grady_vivado;

% Mostrar métricas de comparación
max_diff = max(abs(diff(:)));
mean_diff = mean(abs(diff(:)));

fprintf("Máxima diferencia: %d\n", max_diff);
fprintf("Diferencia media: %f\n", mean_diff);

% Visualizar diferencias
figure;
imagesc(abs(diff));
colorbar;
title("Diferencias absolutas entre grady y grady_vivado");
xlabel("Columnas");
ylabel("Filas");

% Verificar tolerancia
tolerance = 1;
if all(abs(diff(:)) <= tolerance)
    fprintf("Todos los valores están dentro del margen de tolerancia (%d).\n", tolerance);
else
    fprintf("Hay valores fuera del margen de tolerancia (%d).\n", tolerance);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Manejo de datos de magnitud
fileID = fopen('magnitud.txt', 'r');  % Abre el archivo para lectura
if fileID == -1
    error('No se pudo abrir el archivo');
end



% Inicializa la variable A
m = cell(numLines, 1);  % Usamos una celda para almacenar las líneas binarias

% Lee las 1024 líneas
for i = 1:1021
    m{i} = strtrim(fgetl(fileID));  % Lee una línea, elimina los espacios en blanco
    if length(m{i}) ~= 10
        error('Una de las líneas no tiene 9 caracteres. Verifica el archivo.');
    end
end

% Ahora convertimos cada línea (que es una cadena binaria) a un entero con signo
M_signed = zeros(numLines, 1);  % Prealocamos el vector de enteros con signo
cont=2;

for i = 1:1021
    % Convertimos cada línea de caracteres binarios a un número entero
    bin_str = m{i};  % Obtiene la cadena binaria (de 9 bits)

    % Si el primer bit es 1, es un número negativo (complemento a dos)
    if bin_str(1) == '1'
        % Convertir la cadena binaria a número entero sin signo
        unsigned_value = bin2dec(bin_str);
        % Convertir al valor con signo (complemento a dos)
        signed_value = unsigned_value - 2^10;  % 9 bits, restamos 2^9 para obtener el valor negativo
    else
        % Si el primer bit es 0, el número es positivo
        signed_value = bin2dec(bin_str);
    end

    % Guardamos el valor con signo en el arreglo
    M_signed(cont) = signed_value;
    cont++;
end

% Muestra los resultados
%disp(A_signed);

fclose(fileID);  % Cierra el archivo

cont=1;
for i=1:img_width
  for j=1:img_height
    mag_vivado(i,j)=M_signed(cont);
    cont++;
  end
end

% Comparar los valores
diff = magnitudes - mag_vivado;

% Mostrar métricas de comparación
max_diff = max(abs(diff(:)));
mean_diff = mean(abs(diff(:)));

fprintf("Máxima diferencia: %d\n", max_diff);
fprintf("Diferencia media: %f\n", mean_diff);

% Visualizar diferencias
figure;
imagesc(abs(diff));
colorbar;
title("Diferencias absolutas entre magnitudes y mag_vivado");
xlabel("Columnas");
ylabel("Filas");

% Verificar tolerancia
tolerance = 1;
if all(abs(diff(:)) <= tolerance)
    fprintf("Todos los valores están dentro del margen de tolerancia (%d).\n", tolerance);
else
    fprintf("Hay valores fuera del margen de tolerancia (%d).\n", tolerance);
end

