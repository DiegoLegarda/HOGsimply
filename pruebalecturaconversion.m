clc, clear, close all
fileID = fopen('gradx.txt', 'r');  % Abre el archivo para lectura
if fileID == -1
    error('No se pudo abrir el archivo');
end

% Define el número de líneas a leer
numLines = 1021;

% Inicializa la variable A
A = cell(numLines, 1);  % Usamos una celda para almacenar las líneas binarias

% Lee las 1024 líneas
for i = 1:numLines
    A{i} = strtrim(fgetl(fileID));  % Lee una línea, elimina los espacios en blanco
    if length(A{i}) ~= 10
        error('Una de las líneas no tiene 9 caracteres. Verifica el archivo.');
    end
end

% Ahora convertimos cada línea (que es una cadena binaria) a un entero con signo
A_signed = zeros(numLines, 1);  % Prealocamos el vector de enteros con signo
cont=1;

for i = 1:numLines
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

% Muestra los resultados
%disp(A_signed);

fclose(fileID);  % Cierra el archivo



