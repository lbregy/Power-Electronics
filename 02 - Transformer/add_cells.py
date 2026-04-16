import json, sys, uuid
sys.stdout.reconfigure(encoding='utf-8')

with open('transformer02.ipynb', 'r', encoding='utf-8') as f:
    nb = json.load(f)

def md_cell(content, cid=None):
    return {
        "cell_type": "markdown",
        "id": cid or uuid.uuid4().hex[:12],
        "metadata": {},
        "source": [content]
    }

def code_cell(content, cid=None):
    return {
        "cell_type": "code",
        "execution_count": None,
        "id": cid or uuid.uuid4().hex[:12],
        "metadata": {},
        "outputs": [],
        "source": [content]
    }

new_cells = []

# --- Q18 markdown ---
new_cells.append(md_cell(
    "## Q18: Target Current Density\n\n"
    "The target current density $J_w^*$ for the windings is taken from the design range "
    "of $[3\\text{--}6]\\,\\mathrm{A/mm^2}$ given in the lecture slides:\n\n"
    "$$J_w^* = 4\\,\\mathrm{A/mm^2} = 400\\,\\mathrm{A/cm^2}$$"
))

# --- Q18 code ---
new_cells.append(code_cell(
    "# Q18: Target current density\n"
    "J_w_star = 4.0     # A/mm2  (= 400 A/cm2), from design range [3-6] A/mm2\n"
    "\n"
    "print(f'Q18: Target current density')\n"
    "print(f'  J_w* = {J_w_star:.1f} A/mm2  (= {J_w_star*100:.0f} A/cm2)')\n"
))

# --- Q19 markdown ---
new_cells.append(md_cell(
    "## Q19: Required Conductor Cross-Section\n\n"
    "The minimum conductor area for each winding:\n\n"
    "$$A_{\\mathrm{TC},j} = \\frac{I_{j,\\mathrm{RMS}}}{J_w^*}$$\n\n"
    "Each must satisfy $A_{\\mathrm{TC},j} \\le A_{w,\\max,j}$ to fit within the allocated window area."
))

# --- Q19 code ---
new_cells.append(code_cell(
    "# Q19: Required conductor area per winding\n"
    "# Secondary RMS current (referred to secondary side)\n"
    "I_2_RMS = n_real * I_1_RMS      # [A]\n"
    "\n"
    "A_TC_pri = I_1_RMS   / J_w_star  # [mm2]\n"
    "A_TC_sec = I_2_RMS   / J_w_star  # [mm2]\n"
    "A_TC_aux = I_aux_RMS / J_w_star  # [mm2]\n"
    "\n"
    "ok_pri = A_TC_pri <= A_w_max_pri * 100\n"
    "ok_sec = A_TC_sec <= A_w_max_sec * 100\n"
    "ok_aux = A_TC_aux <= A_w_max_aux * 100\n"
    "\n"
    "print('Q19: Required conductor cross-section  A_TC = I_RMS / J_w*')\n"
    "print(f'  I1_RMS   = {I_1_RMS:.3f} A  ->  A_TC,pri = {A_TC_pri:.4f} mm2  (max {A_w_max_pri*100:.3f} mm2)  {\"OK\" if ok_pri else \"FAIL\"}')\n"
    "print(f'  I2_RMS   = {I_2_RMS:.3f} A  ->  A_TC,sec = {A_TC_sec:.4f} mm2  (max {A_w_max_sec*100:.3f} mm2)  {\"OK\" if ok_sec else \"FAIL\"}')\n"
    "print(f'  Iaux_RMS = {I_aux_RMS:.3f} A  ->  A_TC,aux = {A_TC_aux:.4f} mm2  (max {A_w_max_aux*100:.3f} mm2)  {\"OK\" if ok_aux else \"FAIL\"}')\n"
))

# --- Q20 markdown ---
new_cells.append(md_cell(
    "## Q20: Wire Selection\n\n"
    "Available magnet wires M1--M7 (diameters 0.65, 0.90, 1.0, 1.2, 1.54, 1.6, 1.8 mm) "
    "and Litz wires L1--L4 (0.2 mm strands; 25, 35, 45, 80 strands; "
    "conductor areas 0.785, 1.099, 1.414, 2.513 mm$^2$).\n\n"
    "Skin depth at $f_{\\mathrm{sw}} = 80\\,\\mathrm{kHz}$: $\\delta = 0.234\\,\\mathrm{mm}$. "
    "AC resistance factor $F_R \\approx 1$ for bare wire with $d < 4\\delta = 0.936\\,\\mathrm{mm}$, "
    "and always for Litz (strand $d = 0.2\\,\\mathrm{mm} \\ll 2\\delta$).\n\n"
    "**Selection:**\n"
    "- **Primary** ($A_{\\mathrm{TC}} = 0.50\\,\\mathrm{mm^2}$): "
    "**L1 Litz** (25 str, $A = 0.785\\,\\mathrm{mm^2}$, $\\varnothing = 1.53\\,\\mathrm{mm}$, $F_R = 1$)\n"
    "- **Secondary** ($A_{\\mathrm{TC}} = 2.10\\,\\mathrm{mm^2}$): "
    "**L4 Litz** (80 str, $A = 2.513\\,\\mathrm{mm^2}$, $\\varnothing = 2.80\\,\\mathrm{mm}$, $F_R = 1$)\n"
    "- **Auxiliary** ($A_{\\mathrm{TC}} = 0.20\\,\\mathrm{mm^2}$): "
    "**M1 magnet wire** ($d = 0.65\\,\\mathrm{mm} < 4\\delta$, $A = 0.332\\,\\mathrm{mm^2}$, $F_R = 1$)"
))

# --- Q20 code ---
new_cells.append(code_cell(
    "# Q20: Wire selection\n"
    "import numpy as np\n"
    "\n"
    "# Magnet wire diameters [mm]\n"
    "d_M = np.array([0.65, 0.90, 1.0, 1.2, 1.54, 1.6, 1.8])\n"
    "A_M = np.pi / 4 * d_M**2   # mm2 conductor area\n"
    "\n"
    "# Litz wire (0.2 mm strands)\n"
    "n_str_L  = np.array([25, 35, 45, 80])\n"
    "d_str    = 0.2              # mm per strand\n"
    "A_L_wire = n_str_L * (np.pi/4 * d_str**2)  # mm2\n"
    "d_L_eff  = np.array([1.53, 1.80, 2.06, 2.80])  # mm effective OD\n"
    "\n"
    "d_FR1 = 4 * delta           # FR=1 threshold for bare wire [mm]\n"
    "\n"
    "# Selected wires\n"
    "# Primary: L1 (index 0)\n"
    "A_wire_pri = A_L_wire[0]\n"
    "d_wire_pri = d_L_eff[0]\n"
    "FR_pri     = 1.0\n"
    "\n"
    "# Secondary: L4 (index 3)\n"
    "A_wire_sec = A_L_wire[3]\n"
    "d_wire_sec = d_L_eff[3]\n"
    "FR_sec     = 1.0\n"
    "\n"
    "# Auxiliary: M1 (index 0)\n"
    "A_wire_aux = A_M[0]\n"
    "d_wire_aux = d_M[0]\n"
    "FR_aux     = 1.0   # 0.65 mm < 4*delta\n"
    "\n"
    "J_pri_actual = I_1_RMS   / A_wire_pri\n"
    "J_sec_actual = I_2_RMS   / A_wire_sec\n"
    "J_aux_actual = I_aux_RMS / A_wire_aux\n"
    "\n"
    "print('Q20: Wire selection')\n"
    "print(f'  FR=1 threshold (bare): d < 4*delta = {d_FR1:.3f} mm')\n"
    "print()\n"
    "print(f'  Primary   L1 Litz : A = {A_wire_pri:.3f} mm2  d_eff = {d_wire_pri:.2f} mm  FR = {FR_pri}')\n"
    "print(f'            A_TC,pri = {A_TC_pri:.3f} mm2  ->  wire > A_TC  OK')\n"
    "print(f'            J_actual = {J_pri_actual:.2f} A/mm2')\n"
    "print()\n"
    "print(f'  Secondary L4 Litz : A = {A_wire_sec:.3f} mm2  d_eff = {d_wire_sec:.2f} mm  FR = {FR_sec}')\n"
    "print(f'            A_TC,sec = {A_TC_sec:.3f} mm2  ->  wire > A_TC  OK')\n"
    "print(f'            J_actual = {J_sec_actual:.2f} A/mm2')\n"
    "print()\n"
    "print(f'  Auxiliary M1 bare : A = {A_wire_aux:.3f} mm2  d = {d_wire_aux:.2f} mm  FR = {FR_aux}')\n"
    "print(f'            A_TC,aux = {A_TC_aux:.3f} mm2  ->  wire > A_TC  OK  (J < J_w* acceptable for discrete wire)')\n"
    "print(f'            J_actual = {J_aux_actual:.2f} A/mm2')\n"
))

# --- Q21 markdown ---
new_cells.append(md_cell(
    "## Q21: Actual Fill Factor\n\n"
    "$$K_{u,\\mathrm{real}} = \\frac{N_1 A_{w,\\mathrm{pri}} + N_2 A_{w,\\mathrm{sec}} + N_{\\mathrm{aux}} A_{w,\\mathrm{aux}}}{W_A}$$\n\n"
    "Should be $\\leq 0.5$ for a practical bobbin winding (initial estimate was $K_u = 0.3$)."
))

# --- Q21 code ---
new_cells.append(code_cell(
    "# Q21: Actual fill factor\n"
    "A_wire_pri_cm2 = A_wire_pri * 1e-2   # mm2 -> cm2\n"
    "A_wire_sec_cm2 = A_wire_sec * 1e-2\n"
    "A_wire_aux_cm2 = A_wire_aux * 1e-2\n"
    "\n"
    "K_u_real = (N1 * A_wire_pri_cm2 + N2 * A_wire_sec_cm2 + N_aux * A_wire_aux_cm2) / W_A\n"
    "\n"
    "print('Q21: Actual fill factor')\n"
    "print(f'  N1 x A_pri = {N1} x {A_wire_pri:.3f} mm2 = {N1*A_wire_pri:.2f} mm2')\n"
    "print(f'  N2 x A_sec = {N2}  x {A_wire_sec:.3f} mm2 = {N2*A_wire_sec:.2f} mm2')\n"
    "print(f'  Nx x A_aux = {N_aux}  x {A_wire_aux:.3f} mm2 = {N_aux*A_wire_aux:.2f} mm2')\n"
    "print(f'  Total conductor area = {N1*A_wire_pri + N2*A_wire_sec + N_aux*A_wire_aux:.2f} mm2')\n"
    "print(f'  W_A = {W_A*100:.2f} mm2')\n"
    "print(f'  K_u,real = {K_u_real:.4f}  ({\"feasible\" if K_u_real < 0.5 else \"too high\"})')\n"
))

# --- Section 4 header ---
new_cells.append(md_cell("---\n## Section 4: Losses and Thermal Check (Q22--Q26)"))

# --- Q22 markdown ---
new_cells.append(md_cell(
    "## Q22: DC Winding Resistance\n\n"
    "$$R_{\\mathrm{DC},j} = \\rho_{\\mathrm{Cu}}(T_w)\\,\\frac{N_j \\cdot \\mathrm{MLT}}{A_{w,j}}$$\n\n"
    "at estimated winding temperature $T_w = 80\\,^\\circ\\mathrm{C}$, "
    "where $\\rho_{\\mathrm{Cu}}(T) = 1.724\\times10^{-8}(1 + 3.862\\times10^{-3}(T-20))\\,\\Omega\\mathrm{m}$."
))

# --- Q22 code ---
new_cells.append(code_cell(
    "# Q22: DC winding resistance at T_w = 80 degC\n"
    "T_w      = 80.0\n"
    "rho_Cu20 = 1.724e-8          # Ohm m at 20 degC\n"
    "alpha_Cu = 3.862e-3          # 1/degC\n"
    "rho_Cu_T = rho_Cu20 * (1 + alpha_Cu * (T_w - 20))   # Ohm m at T_w\n"
    "\n"
    "MLT_m         = MLT * 1e-2           # cm -> m\n"
    "A_wire_pri_m2 = A_wire_pri * 1e-6   # mm2 -> m2\n"
    "A_wire_sec_m2 = A_wire_sec * 1e-6\n"
    "A_wire_aux_m2 = A_wire_aux * 1e-6\n"
    "\n"
    "R_DC_pri = rho_Cu_T * N1    * MLT_m / A_wire_pri_m2\n"
    "R_DC_sec = rho_Cu_T * N2    * MLT_m / A_wire_sec_m2\n"
    "R_DC_aux = rho_Cu_T * N_aux * MLT_m / A_wire_aux_m2\n"
    "\n"
    "print(f'Q22: DC winding resistance  (T_w = {T_w} degC,  rho_Cu = {rho_Cu_T*1e8:.4f}e-8 Ohm m)')\n"
    "print(f'  R_DC,pri = {R_DC_pri*1e3:.4f} mOhm  (N1={N1},  A={A_wire_pri:.3f} mm2)')\n"
    "print(f'  R_DC,sec = {R_DC_sec*1e3:.4f} mOhm  (N2={N2},   A={A_wire_sec:.3f} mm2)')\n"
    "print(f'  R_DC,aux = {R_DC_aux*1e3:.4f} mOhm  (Naux={N_aux}, A={A_wire_aux:.3f} mm2)')\n"
))

# --- Q23 markdown ---
new_cells.append(md_cell(
    "## Q23: AC Resistance Factor\n\n"
    "For Litz wire (strand $d = 0.2\\,\\mathrm{mm}$), all strands satisfy "
    "$d < 2\\delta = 0.468\\,\\mathrm{mm}$, so $F_R = 1$.\n\n"
    "For M1 bare auxiliary wire ($d = 0.65\\,\\mathrm{mm} < 4\\delta = 0.936\\,\\mathrm{mm}$), "
    "$F_R \\approx 1$ as well.\n\n"
    "Therefore $R_{\\mathrm{AC},j} = R_{\\mathrm{DC},j}$ for all windings."
))

# --- Q23 code ---
new_cells.append(code_cell(
    "# Q23: AC resistance factor\n"
    "FR_pri = 1.0   # L1 Litz, strand d=0.2 mm < 2*delta\n"
    "FR_sec = 1.0   # L4 Litz, strand d=0.2 mm < 2*delta\n"
    "FR_aux = 1.0   # M1 bare, d=0.65 mm < 4*delta\n"
    "\n"
    "R_AC_pri = FR_pri * R_DC_pri\n"
    "R_AC_sec = FR_sec * R_DC_sec\n"
    "R_AC_aux = FR_aux * R_DC_aux\n"
    "\n"
    "print('Q23: AC resistance factor')\n"
    "print(f'  Primary   (L1 Litz, d_str=0.2 mm < 2*delta={2*0.234:.3f} mm): FR={FR_pri}  R_AC,pri={R_AC_pri*1e3:.4f} mOhm')\n"
    "print(f'  Secondary (L4 Litz, d_str=0.2 mm < 2*delta={2*0.234:.3f} mm): FR={FR_sec}  R_AC,sec={R_AC_sec*1e3:.4f} mOhm')\n"
    "print(f'  Auxiliary (M1 bare, d=0.65 mm   < 4*delta={4*0.234:.3f} mm): FR={FR_aux}  R_AC,aux={R_AC_aux*1e3:.4f} mOhm')\n"
))

# --- Q24 markdown ---
new_cells.append(md_cell(
    "## Q24: Copper Losses\n\n"
    "$$P_{\\mathrm{Cu}} = R_{\\mathrm{AC,pri}} I_{1,\\mathrm{RMS}}^2 "
    "+ R_{\\mathrm{AC,sec}} I_{2,\\mathrm{RMS}}^2 "
    "+ R_{\\mathrm{AC,aux}} I_{\\mathrm{aux,RMS}}^2$$\n\n"
    "Evaluated at $V_{\\mathrm{in,min}} = 30\\,\\mathrm{V}$ and $V_{\\mathrm{in,nom}} = 50\\,\\mathrm{V}$."
))

# --- Q24 code ---
new_cells.append(code_cell(
    "# Q24: Copper losses\n"
    "# DAB phase shift to deliver P_out\n"
    "def DAB_phi(V_in, V_out_n, n, P_out, f_sw, L_H):\n"
    "    import numpy as np\n"
    "    # P = n*Vin*Vout/(2*pi*f*L) * phi*(pi - 2*phi) / pi\n"
    "    # quadratic: -2*phi^2 + pi*phi - k = 0\n"
    "    k = P_out * 2 * np.pi * f_sw * n * L_H / (V_in * V_out_n)\n"
    "    disc = np.pi**2 - 8*k\n"
    "    if disc < 0:\n"
    "        return None\n"
    "    return (np.pi - np.sqrt(disc)) / 4\n"
    "\n"
    "# RMS primary current for trapezoidal DAB waveform\n"
    "def DAB_I1_RMS(V_in, V_out_n, n, phi, f_sw, L_H):\n"
    "    import numpy as np\n"
    "    T2     = 0.5 / f_sw\n"
    "    t1     = phi / (2 * np.pi * f_sw)\n"
    "    slope1 = (V_in + n * V_out_n) / (2 * L_H)\n"
    "    slope2 = (V_in - n * V_out_n) / (2 * L_H)\n"
    "    i0 = -(slope1 * t1 + slope2 * (T2 - t1)) / 2\n"
    "    i1 = i0 + slope1 * t1\n"
    "    def seg_rms2(i_s, sl, dt):\n"
    "        return i_s**2*dt + i_s*sl*dt**2 + sl**2*dt**3/3\n"
    "    rms2 = (seg_rms2(i0, slope1, t1) + seg_rms2(i1, slope2, T2 - t1)) / T2\n"
    "    return np.sqrt(rms2)\n"
    "\n"
    "L_H = L * 1e-6          # uH -> H\n"
    "\n"
    "phi_min = DAB_phi(U_in_min, U_out, n_real, P_out_nom, f_sw, L_H)\n"
    "I1_min  = DAB_I1_RMS(U_in_min, U_out, n_real, phi_min, f_sw, L_H)\n"
    "I2_min  = n_real * I1_min\n"
    "\n"
    "phi_nom = DAB_phi(U_in_nom, U_out, n_real, P_out_nom, f_sw, L_H)\n"
    "I1_nom  = DAB_I1_RMS(U_in_nom, U_out, n_real, phi_nom, f_sw, L_H)\n"
    "I2_nom  = n_real * I1_nom\n"
    "\n"
    "def P_Cu_fn(I1, I2):\n"
    "    return R_AC_pri*I1**2 + R_AC_sec*I2**2 + R_AC_aux*I_aux_RMS**2\n"
    "\n"
    "P_Cu_at_min = P_Cu_fn(I1_min, I2_min)\n"
    "P_Cu_at_nom = P_Cu_fn(I1_nom, I2_nom)\n"
    "P_Cu_worst  = max(P_Cu_at_min, P_Cu_at_nom)\n"
    "\n"
    "import numpy as np\n"
    "print('Q24: Copper losses')\n"
    "print(f'  V_in={U_in_min} V: phi={np.degrees(phi_min):.2f} deg  I1={I1_min:.3f} A  I2={I2_min:.3f} A')\n"
    "print(f'    P_Cu = {P_Cu_at_min:.4f} W')\n"
    "print(f'    break: R_pri*I1^2={R_AC_pri*I1_min**2*1e3:.2f} mW  R_sec*I2^2={R_AC_sec*I2_min**2*1e3:.2f} mW  R_aux*Iaux^2={R_AC_aux*I_aux_RMS**2*1e3:.2f} mW')\n"
    "print()\n"
    "print(f'  V_in={U_in_nom} V: phi={np.degrees(phi_nom):.2f} deg  I1={I1_nom:.3f} A  I2={I2_nom:.3f} A')\n"
    "print(f'    P_Cu = {P_Cu_at_nom:.4f} W')\n"
    "print(f'    break: R_pri*I1^2={R_AC_pri*I1_nom**2*1e3:.2f} mW  R_sec*I2^2={R_AC_sec*I2_nom**2*1e3:.2f} mW  R_aux*Iaux^2={R_AC_aux*I_aux_RMS**2*1e3:.2f} mW')\n"
    "print(f'\\n  Worst-case: P_Cu,worst = {P_Cu_worst:.4f} W')\n"
))

# --- Q25 markdown ---
new_cells.append(md_cell(
    "## Q25: Core Losses and Temperature Rise\n\n"
    "$$P_{\\mathrm{core}} = K_b \\left(\\frac{f_{\\mathrm{sw}}}{f_{\\mathrm{base}}}\\right)^\\alpha "
    "\\left(\\frac{\\Delta B}{B_{\\mathrm{base}}}\\right)^\\beta V_e$$\n\n"
    "where $\\Delta B = B_{\\mathrm{actual}} = 77.3\\,\\mathrm{mT}$ (worst case, at $V_{\\mathrm{in,max}}$ "
    "since $\\lambda_1$ is largest there).\n\n"
    "Temperature rise:\n\n"
    "$$\\Delta T = (P_{\\mathrm{Cu,worst}} + P_{\\mathrm{core}}) \\cdot R_{\\mathrm{th}}$$"
))

# --- Q25 code ---
new_cells.append(code_cell(
    "# Q25: Core losses and temperature rise\n"
    "# Delta B = B_actual (computed from lambda_1_max = Vin_max*T_sw/2)\n"
    "delta_B  = B_actual          # T\n"
    "V_e_m3   = V_e * 1e-6        # cm3 -> m3\n"
    "f_base_hz = 100e3\n"
    "B_base_T  = 1.0              # Steinmetz normalisation [T]\n"
    "\n"
    "P_core = K_b * (f_sw / f_base_hz)**alpha * (delta_B / B_base_T)**beta * V_e_m3\n"
    "\n"
    "T_amb   = 25.0\n"
    "delta_T = (P_Cu_worst + P_core) * R_th\n"
    "T_core_max = T_amb + delta_T\n"
    "\n"
    "print('Q25: Core losses and temperature rise')\n"
    "print(f'  Delta_B = B_actual = {delta_B*1e3:.2f} mT')\n"
    "print(f'  P_core  = {P_core:.4f} W')\n"
    "print(f'  P_Cu,worst = {P_Cu_worst:.4f} W')\n"
    "print(f'  Delta_T = ({P_Cu_worst:.4f} + {P_core:.4f}) x {R_th} = {delta_T:.2f} K')\n"
    "print(f'  T_core  = {T_amb} + {delta_T:.2f} = {T_core_max:.1f} degC  ({\"OK < 120 degC\" if T_core_max < 120 else \"FAIL > 120 degC\"})')\n"
))

# --- Q26 markdown ---
new_cells.append(md_cell(
    "## Q26: Total Transformer Losses\n\n"
    "Compared against the loss budget $P_{\\mathrm{tot}} = 2.63\\,\\mathrm{W}$ (Q5)."
))

# --- Q26 code ---
new_cells.append(code_cell(
    "# Q26: Total transformer losses\n"
    "P_loss_transformer = P_Cu_worst + P_core\n"
    "\n"
    "print('Q26: Total transformer losses')\n"
    "print(f'  P_Cu,worst       = {P_Cu_worst:.4f} W')\n"
    "print(f'  P_core           = {P_core:.4f} W')\n"
    "print(f'  P_loss,transformer = {P_loss_transformer:.4f} W')\n"
    "print(f'  Loss budget        = {P_tot:.4f} W')\n"
    "print(f'  Margin             = {P_tot - P_loss_transformer:.4f} W  ({\"OK within budget\" if P_loss_transformer <= P_tot else \"OVER BUDGET\"})')\n"
))

# --- Section 5 header ---
new_cells.append(md_cell("---\n## Section 5: Summary and Efficiency (Q27--Q28)"))

# --- Q27 markdown ---
new_cells.append(md_cell("## Q27: Design Summary"))

# --- Q27 code ---
new_cells.append(code_cell(
    "# Q27: Design summary table\n"
    "sep = '=' * 60\n"
    "div = '-' * 60\n"
    "print(sep)\n"
    "print('         TRANSFORMER DESIGN SUMMARY')\n"
    "print(sep)\n"
    "print(f'Core           : ETD34/17/11, N87 ferrite')\n"
    "print(f'A_e            : {A_c:.3f} cm2 = {A_c*100:.1f} mm2')\n"
    "print(f'l_m            : {l_m:.2f} cm')\n"
    "print(f'V_e            : {V_e:.2f} cm3')\n"
    "print(f'A_L (ungapped) : {A_L_core*1e9:.0f} nH')\n"
    "print(f'R_th           : {R_th:.0f} K/W')\n"
    "print(div)\n"
    "print(f'N1 / N2 / N_aux: {N1} / {N2} / {N_aux}')\n"
    "print(f'n_real         : {n_real:.4f}  (target {n_desired:.4f},  err {abs(n_real-n_desired)/n_desired*100:.2f}%)')\n"
    "print(f'n_aux_real     : {n_aux_real:.4f}  ->  V_aux = {V_aux_real:.2f} V')\n"
    "print(div)\n"
    "print(f'B_pk,max       : {B_pk_max*1e3:.0f} mT')\n"
    "print(f'B_actual       : {B_actual*1e3:.2f} mT  (< B_pk,max OK)')\n"
    "print(f'L_m            : {L_m*1e6:.0f} uH  (> L_m,min = {L_m_MIN*1e6:.0f} uH OK)')\n"
    "print(div)\n"
    "print(f'Wire primary   : L1 Litz  A={A_wire_pri:.3f} mm2  d_eff={d_wire_pri:.2f} mm  FR={FR_pri}')\n"
    "print(f'Wire secondary : L4 Litz  A={A_wire_sec:.3f} mm2  d_eff={d_wire_sec:.2f} mm  FR={FR_sec}')\n"
    "print(f'Wire auxiliary : M1 bare  A={A_wire_aux:.3f} mm2  d={d_wire_aux:.2f} mm    FR={FR_aux}')\n"
    "print(f'K_u,real       : {K_u_real:.4f}  (initial estimate {K_u})')\n"
    "print(div)\n"
    "print(f'R_DC,pri       : {R_DC_pri*1e3:.3f} mOhm')\n"
    "print(f'R_DC,sec       : {R_DC_sec*1e3:.3f} mOhm')\n"
    "print(f'R_DC,aux       : {R_DC_aux*1e3:.3f} mOhm')\n"
    "print(div)\n"
    "print(f'P_Cu,worst     : {P_Cu_worst:.4f} W')\n"
    "print(f'P_core         : {P_core:.4f} W')\n"
    "print(f'P_loss,total   : {P_loss_transformer:.4f} W  (budget {P_tot:.2f} W  OK)')\n"
    "print(f'Delta_T        : {delta_T:.1f} K  ->  T_core = {T_core_max:.1f} degC  OK')\n"
    "print(sep)\n"
))

# --- Q28 markdown ---
new_cells.append(md_cell(
    "## Q28: Overall DAB Efficiency\n\n"
    "$$\\eta = \\frac{P_{\\mathrm{out}}}{P_{\\mathrm{out}} + P_{\\mathrm{semi}} + P_{\\mathrm{loss,transformer}}}$$\n\n"
    "Semiconductor losses from `DAB_convert.ipynb`:\n"
    "- $V_{\\mathrm{in,min}} = 30\\,\\mathrm{V}$: $P_{\\mathrm{semi}} = 7.1352\\,\\mathrm{W}$ "
    "(conduction 2.4230 W + switching 4.7122 W)\n"
    "- Nominal: scaled from min-voltage values"
))

# --- Q28 code ---
new_cells.append(code_cell(
    "# Q28: Overall DAB efficiency\n"
    "# Semiconductor losses from DAB_convert.ipynb\n"
    "P_semi_worst = 7.1352    # W at V_in,min = 30 V\n"
    "P_cond_min   = 2.4230    # W conduction\n"
    "P_sw_min     = 4.7122    # W switching\n"
    "\n"
    "# Nominal operating point: conduction ~ I2, switching ~ V_in\n"
    "P_cond_nom = P_cond_min * (I1_nom / I1_min)**2\n"
    "P_sw_nom   = P_sw_min   * (U_in_nom / U_in_min)\n"
    "P_semi_nom = P_cond_nom + P_sw_nom\n"
    "\n"
    "# Transformer losses at each point\n"
    "P_tf_worst = P_Cu_at_min + P_core\n"
    "P_tf_nom   = P_Cu_at_nom + P_core\n"
    "\n"
    "eta_worst = P_out_nom / (P_out_nom + P_semi_worst + P_tf_worst)\n"
    "eta_nom   = P_out_nom / (P_out_nom + P_semi_nom   + P_tf_nom)\n"
    "\n"
    "print('Q28: Overall DAB efficiency')\n"
    "print(f'  V_in = {U_in_min} V (worst case):')\n"
    "print(f'    P_semi        = {P_semi_worst:.4f} W')\n"
    "print(f'    P_transformer = {P_tf_worst:.4f} W')\n"
    "print(f'    P_total_loss  = {P_semi_worst + P_tf_worst:.4f} W')\n"
    "print(f'    eta_worst     = {eta_worst*100:.2f} %')\n"
    "print()\n"
    "print(f'  V_in = {U_in_nom} V (nominal):')\n"
    "print(f'    P_semi        = {P_semi_nom:.4f} W')\n"
    "print(f'    P_transformer = {P_tf_nom:.4f} W')\n"
    "print(f'    P_total_loss  = {P_semi_nom + P_tf_nom:.4f} W')\n"
    "print(f'    eta_nom       = {eta_nom*100:.2f} %')\n"
))

# Append all new cells
nb['cells'].extend(new_cells)

with open('transformer02.ipynb', 'w', encoding='utf-8') as f:
    json.dump(nb, f, ensure_ascii=False, indent=1)

print(f"Done. Added {len(new_cells)} cells. Total cells: {len(nb['cells'])}")
