# 8point_fft-asic-rtl-to-gdsii
Complete RTL-to-GDSII implementation of an 8-point pipelined Radix-2 DIT FFT using Verilog, SKY130 HD, Yosys, and OpenROAD.

<img width="1057" height="890" alt="image" src="https://github.com/user-attachments/assets/ff793fac-dd4d-4420-83e1-e999fccc6666" />

# PROJECT STRUCTURE
fft8-asic-rtl-to-gdsii/
│
├── rtl/
│   └── DITFFT_8_point.v
│
├── tb/
│   └── DITFFT_8_point_tb.v
│
├── asic/
│   ├── config.mk
│   ├── constraint.sdc
│   │
│   ├── reports/
│   │   ├── synth_stat.txt
│   │   ├── 2_floorplan_final.rpt
│   │   ├── 3_global_place.rpt
│   │   ├── 3_detailed_place.rpt
│   │   ├── 3_resizer.rpt
│   │   ├── 4_cts_final.rpt
│   │   ├── 5_global_route.rpt
│   │   ├── 6_finish.rpt
│   │   └── 6_drc_count.rpt
│   │
│   ├── results/
│   │   ├── 6_final.gds
│   │   ├── 6_final.def
│   │   ├── 6_final.v
│   │   ├── 6_final.spef
│   │   └── 6_final.cdl
│   │
│   └── screenshots/
│       ├── final_layout.webp
│       ├── final_routing.webp
│       ├── final_placement.webp
│       ├── final_congestion.webp
│       ├── cts_clk.webp
│       └── final_worst_path.webp
│
├── docs/
│   ├── architecture.png
│   └── flow_diagram.png
│
├── README.md
├── LICENSE
└── .gitignore


# DESIGN SPECIFICATIONS

| Parameter | Value |
| Architecture | 8-Point Pipelined Radix-2 DIT FFT |
| RTL Language | Verilog |
| Arithmetic | Fixed-Point (Q1.15) |
| Datapath Width | 16-bit Signed |
| Technology | SKY130 HD |
| Clock Target | 100 MHz |

# Implementation Results

| Standard Cells | 5,740 |
| Cell Area | 57,463.86 μm² |
| Final Design Area | 63,490 μm² |
| Die Area | 310 μm × 310 μm |
| Core Utilization | 77.60 % |
| Worst Setup Slack | +0.62 ns |
| Worst Hold Slack | +0.34 ns |
| Estimated Maximum Frequency | 106.63 MHz |
| Routing DRC Violations | 0 |


# Static Timing Analysis
The design successfully met timing under the analyzed Typical-Typical (TT) process corner. Future Work - SS and FF timing analysis

| Clock Constraint | 10 ns |
| Worst Setup Slack | +0.62 ns |
| Worst Hold Slack | +0.34 ns |
| Setup Violations | 0 |
| Hold Violations | 0 |
The achieved minimum clock period corresponds to an estimated operating frequency of approximately 106.63 MHz, exceeding the original 100 MHz design target.

# Physical Design

## Placement
<img width="1100" height="1100" alt="final_placement" src="https://github.com/user-attachments/assets/c6e6cfd2-9c7f-4cf1-938f-dd484d14d671" />

## Clock Tree 
<img width="1100" height="1100" alt="cts_clk_layout" src="https://github.com/user-attachments/assets/fbd2813b-69be-4d29-bdef-9346c9a9f793" />

## Routing
<img width="1100" height="1100" alt="final_routing" src="https://github.com/user-attachments/assets/feef43cd-0666-4540-898b-bc42602603c1" />

## Congestion
<img width="1100" height="1100" alt="final_congestion" src="https://github.com/user-attachments/assets/9390a8ea-df12-46e8-a5fe-916a92dd3a02" />

## Final Layout
<img width="1100" height="1100" alt="final_all" src="https://github.com/user-attachments/assets/7a4ca2f4-409c-4c62-83a9-4b055feb3fcf" />

## Critcial Path
<img width="1100" height="1100" alt="final_worst_path" src="https://github.com/user-attachments/assets/a390dc7a-67d3-4b2c-8665-eb43b8238661" />


# Tools Used

| RTL Design | Verilog |
| Functional Simulation | Xilinx Vivado |
| Logic Synthesis | Yosys |
| Physical Design | OpenROAD |
| Timing Analysis | OpenSTA |
| PDK | SkyWater SKY130 HD |
All using WSL + Docker

## Future Work
- Gate-Level Simulation (GLS)
- SDF-annotated timing simulation
- Multi-corner timing analysis (FF/SS)
- Complete LVS sign-off (simulated, with clean DRC/LVS but no report generated due to version constraints) 
- Learning Formal Verification ( integration of SymbiYosys into this design ) 

| Layout Viewer | KLayout |

