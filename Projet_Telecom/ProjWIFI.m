%% BE OFDM - version finale corrigée (TEB corrects)
close all; clear; clc;
rng(0);

% ---------------------------
% Paramètres
% ---------------------------
N = 16;           % nombre de porteuses
n = 1000;         % nombre de symboles OFDM
N_bits = N * n;
Ts = 1;           % durée symbole monoporteuse (unitée)
Te = Ts;
Fe = 1/Te;

% ---------------------------
% utilitaires
% ---------------------------
% démultiplexer BPSK : prend une matrice complexe (N x n) ou vecteur (N*n x 1)
% et renvoie les bits 0/1 dans l'ordre colonne par colonne
function bits_out = bpsk_demod(mat)
    v = real(mat(:));               % vecteur colonne
    decided = sign(v);              % ±1 (sign(0)=0)
    decided(decided==0) = 1;        % si exactement 0 -> +1
    bits_out = (decided + 1) / 2;   % -1->0, +1->1
end

% ---------------------------
% Génération des bits et mapping BPSK
% ---------------------------
bits = randi([0 1], 1, N_bits);      % 1 x (N*n)
symbols = 2*bits - 1;                % ±1 BPSK

% Réorganisation en matrice (N x n)
mul_port = reshape(symbols, [N, n]); % colonnes = symboles OFDM

% ---------------------------
% IFFT : génération du signal OFDM (toutes porteuses)
% ---------------------------
Xall = ifft(mul_port, N, 1);         % N x n (temporal OFDM samples per col)
txall = Xall(:).';                   % 1 x (N*n) pour analyse temporelle

% DSP : exemple de tracés (optionnel)
[Sxall, fall] = pwelch(txall, hamming(256), 128, 1024, Fe, 'centered');
figure; plot(fall/Fe, 10*log10(fftshift(Sxall))); grid on;
xlabel('Fréquence normalisée (f/Fe)'); ylabel('DSP (dB)'); title('DSP - Toutes les porteuses'); xlim([-0.5 0.5]);

% ---------------------------
% Réception sans canal (vérification IFFT/FFT)
% ---------------------------
FFTx = fft(Xall, N, 1);              % doit retrouver mul_port (±1)
bits_rx_nocanal = bpsk_demod(FFTx);
TEB_sans_canal = sum(bits(:).' ~= bits_rx_nocanal) / (N_bits);
fprintf('TEB sans canal: %g (doit être 0 ou très proche)\n', TEB_sans_canal);

% ---------------------------
% Canal multi-trajets (Rayleigh) sans bruit
% ---------------------------
Npath = 4;
P_dB = [0 -3 -6 -9];
P_lin = 10.^(P_dB/10);
P_norm = P_lin / sum(P_lin);
h_channel = sqrt(P_norm/2) .* (randn(1, Npath) + 1j*randn(1, Npath));  % 1 x Npath

% réponse en fréquence (N sous-porteuses)
H_freq = fft(h_channel, N);   % 1 x N (complexe)
module = abs(H_freq);
phase_deg = angle(H_freq) * 180/pi;

figure('Position',[100 100 1000 400]);
subplot(1,2,1); plot(0:N-1, module, 'o-','LineWidth',1.2); grid on;
xlabel('Indice de porteuse k'); ylabel('|H(k)|'); title('Module de H(k)'); xlim([0 N-1]);
subplot(1,2,2); plot(0:N-1, phase_deg, 'o-','LineWidth',1.2); grid on;
xlabel('Indice de porteuse k'); ylabel('Phase (°)'); title('Phase de H(k)'); xlim([0 N-1]);

% ---------------------------
% Calcul du nombre de porteuses utiles pour 20% de perte
% ---------------------------
L = Npath - 1;
perte = 0.2;
N_utile_20 = L * (1/perte - 1);
fprintf('Pour 20%% de perte, N_utile minimum = %d (L = %d)\n', N_utile_20, L);
fprintf('Nous utilisons N = %d porteuses dans la simulation.\n', N);

% ---------------------------
% Passage du signal OFDM dans le canal (sans IG ni PC)
% ---------------------------
signal_ofdm_concat = Xall(:).';
signal_rx_canal = filter(h_channel, 1, signal_ofdm_concat);    % convolution
signal_rx_canal = reshape(signal_rx_canal, N, n);              % N x n

% TEB sans égalisation (après FFT)
symbols_rx_canal = fft(signal_rx_canal, N, 1);
bits_rx_noIG = bpsk_demod(symbols_rx_canal);
TEB_sans_IG = sum(bits(:).' ~= bits_rx_noIG) / (N_bits);
fprintf('TEB sans IG/PC (canal multitrajet, sans égalisation) : %g\n', TEB_sans_IG);

% ---------------------------
% Intervalle de garde composé de zéros (IG)
% ---------------------------
L_IG = 5;   % exemple
SignalOFDM_IG = zeros(N + L_IG, n);
for ii = 1:n
    symbole_temp = Xall(:, ii);
    SignalOFDM_IG(:, ii) = [zeros(L_IG,1); symbole_temp];
end
SignalOFDM_IG_vec = SignalOFDM_IG(:).';
SignalSortieCanal = filter(h_channel, 1, SignalOFDM_IG_vec);
SignalSortie_matriciel = reshape(SignalSortieCanal, N + L_IG, n);
SignalSansIG = SignalSortie_matriciel(L_IG+1:end, :);   % N x n
symbols_rx_IG = fft(SignalSansIG, N, 1);
bits_rx_avecIG = bpsk_demod(symbols_rx_IG);
TEB_avec_IG = sum(bits(:).' ~= bits_rx_avecIG) / (N_bits);
fprintf('TEB avec IG (zeros) : %g\n', TEB_avec_IG);

% ---------------------------
% Préfixe Cyclique (PC)
% ---------------------------
L_PC = L;   % on prend L_PC = Npath-1
SignalOFDM_PC = zeros(N + L_PC, n);
for ii = 1:n
    symbole = Xall(:, ii);                     % N x 1
    prefixe = symbole(end-L_PC+1:end);         % L_PC x 1
    SignalOFDM_PC(:, ii) = [prefixe; symbole]; % (N+L_PC) x 1
end
SignalOFDM_PC_vec = SignalOFDM_PC(:).';
SignalSortieCanal_PC = filter(h_channel, 1, SignalOFDM_PC_vec);
SignalSortie_PC_mat = reshape(SignalSortieCanal_PC, N + L_PC, n);
SignalSansPC = SignalSortie_PC_mat(L_PC+1:end, :);   % N x n (aligné)
symbols_rx_PC = fft(SignalSansPC, N, 1);

% TEB avant égalisation (après PC enlevé mais avant equalisation)
bits_rx_PC = bpsk_demod(symbols_rx_PC);
TEB_PC = sum(bits(:).' ~= bits_rx_PC) / (N_bits);
fprintf('TEB avec Préfixe Cyclique (avant égalisation) : %g\n', TEB_PC);

% ---------------------------
% Egaliseurs (PC utilisé, canal connu)
% ---------------------------
% Vecteur H (N x 1) pour alignement
H_col = H_freq(:);   % N x 1 (complex)

% ---- ZF : division par H ----
% Ici nous réalisons la division exacte : symbols_eq = symbols_rx_PC ./ H
% (pas de régularisation, puisque pas de bruit)
symbols_eq_ZF = symbols_rx_PC ./ repmat(H_col, 1, n);   % N x n
bits_rx_PC_ZF = bpsk_demod(symbols_eq_ZF);
TEB_PC_ZF = sum(bits(:).' ~= bits_rx_PC_ZF) / (N_bits);
fprintf('TEB avec Préfixe Cyclique + ZF : %g\n', TEB_PC_ZF);

% Vérification stricte (assert) : TEB_PC_ZF doit être 0 dans ces conditions idéales
if TEB_PC_ZF ~= 0
    warning('TEB_PC_ZF n''est pas égal à 0 : %g. Vérifier H(k)==0 ou précision numérique.', TEB_PC_ZF);
else
    fprintf('Vérification : TEB_PC_ZF == 0 (OK dans conditions idéales sans bruit).\n');
end

% ---- "ML" (multiplication par conj(H) telle que dans l''énoncé) ----
H_ML = conj(H_freq(:));                        % N x 1
symbols_eq_ML = symbols_rx_PC .* repmat(H_ML, 1, n);
bits_rx_PC_ML = bpsk_demod(symbols_eq_ML);
TEB_PC_ML = sum(bits(:).' ~= bits_rx_PC_ML) / (N_bits);
fprintf('TEB avec Préfixe Cyclique + ML (conj(H) sans normalisation) : %g\n', TEB_PC_ML);

% ---------------------------
% Affichage de quelques constellations pour inspection
% ---------------------------
k1 = 3; k2 = 14;
figure('Position',[100 100 1000 700]);
subplot(3,2,1); plot(real(symbols_rx_canal(k1,:)), imag(symbols_rx_canal(k1,:)), 'x'); grid on; title(sprintf('sans IG/PC - porteuse %d', k1)); axis equal;
subplot(3,2,2); plot(real(symbols_rx_canal(k2,:)), imag(symbols_rx_canal(k2,:)), 'x'); grid on; title(sprintf('sans IG/PC - porteuse %d', k2)); axis equal;
subplot(3,2,3); plot(real(symbols_rx_IG(k1,:)), imag(symbols_rx_IG(k1,:)), 'x'); grid on; title(sprintf('avec IG - porteuse %d', k1)); axis equal;
subplot(3,2,4); plot(real(symbols_rx_IG(k2,:)), imag(symbols_rx_IG(k2,:)), 'x'); grid on; title(sprintf('avec IG - porteuse %d', k2)); axis equal;
subplot(3,2,5); plot(real(symbols_rx_PC(k1,:)), imag(symbols_rx_PC(k1,:)), 'x'); grid on; title(sprintf('avec PC (avant ZF) - porteuse %d', k1)); axis equal;
subplot(3,2,6); plot(real(symbols_eq_ZF(k1,:)), imag(symbols_eq_ZF(k1,:)), 'x'); grid on; title(sprintf('après ZF - porteuse %d (devrait être ±1)', k1)); axis equal;

% Fin
fprintf('Simulation terminée.\n');
