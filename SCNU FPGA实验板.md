# SCNU FPGA实验板相关资料

## 板载资源

- 配置
    - ALTERA Cyclone IV EP4CE6E22C8N
    - EPCS4N
- 外设
    - 1块50MHz有源晶振
    - 6位动态刷新共阳数码管
    - 8个按键，常高电平，触发时低电平
    - 8个LED灯，低电平亮
    - 33空闲I/O

## 引脚分布

数码管数据引脚：

| 名称 | 引脚 |
| ------ | ------ |
| SEG_LED1 | PIN_135 |
| SEG_LED2 | PIN_136 |
| SEG_LED3 | PIN_137 |
| SEG_LED4 | PIN_138 |
| SEG_LED5 | PIN_141 |
| SEG_LED6 | PIN_142 |
| SEG_LED7 | PIN_143 |
| SEG_LED8 | PIN_144 |

数码管位选引脚：

| 名称 | 引脚 |
| ------ | ------ |
| SEG_nCS1 | PIN_1 |
| SEG_nCS2 | PIN_2 |
| SEG_nCS3 | PIN_3 |
| SEG_nCS4 | PIN_129 |
| SEG_nCS5 | PIN_132 |
| SEG_nCS6 | PIN_133 |

LED引脚：

| 名称 | 引脚 |
| ------ | ------ |
| LED1 | PIN_28 |
| LED2 | PIN_31 |
| LED3 | PIN_33 |
| LED4 | PIN_38 |
| LED5 | PIN_42 |
| LED6 | PIN_44 |
| LED7 | PIN_49 |
| LED8 | PIN_51 |

按键引脚：

| 名称 | 引脚 |
| ------ | ------ |
| BUT1 | PIN_30 |
| BUT2 | PIN_32 |
| BUT3 | PIN_34 |
| BUT4 | PIN_39 |
| BUT5 | PIN_43 |
| BUT6 | PIN_46 |
| BUT7 | PIN_50 |
| BUT8 | PIN_52 |

I/O引脚：

67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 80, 83, 84, 85, 86, 87, 98, 99, 100, 101, 103, 104, 105, 106, 110, 111, 112, 113, 114, 115, 126, 127

## TCL文件示例

```tcl
# SCNU FPGA tcl script example
# 将 seg_cs 等改为你自己的结点名称

set_global_assignment -name RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED"

set_global_assignment -name ENABLE_INIT_DONE_OUTPUT OFF

set_location_assignment PIN_23  -to clk_50mhz

set_location_assignment PIN_133 -to seg_cs[5]
set_location_assignment PIN_132 -to seg_cs[4]
set_location_assignment PIN_129 -to seg_cs[3]
set_location_assignment PIN_3   -to seg_cs[2]
set_location_assignment PIN_2   -to seg_cs[1]
set_location_assignment PIN_1   -to seg_cs[0]

set_location_assignment PIN_144 -to seg_data[7]
set_location_assignment PIN_143 -to seg_data[6]
set_location_assignment PIN_142 -to seg_data[5]
set_location_assignment PIN_141 -to seg_data[4]
set_location_assignment PIN_138 -to seg_data[3]
set_location_assignment PIN_137 -to seg_data[2]
set_location_assignment PIN_136 -to seg_data[1]
set_location_assignment PIN_135 -to seg_data[0]

set_location_assignment PIN_52  -to key[7]
set_location_assignment PIN_50  -to key[6]
set_location_assignment PIN_46  -to key[5]
set_location_assignment PIN_43  -to key[4]
set_location_assignment PIN_39  -to key[3]
set_location_assignment PIN_34  -to key[2]
set_location_assignment PIN_32  -to key[1]
set_location_assignment PIN_30  -to key[0]

set_location_assignment PIN_51  -to led[7]
set_location_assignment PIN_49  -to led[6]
set_location_assignment PIN_44  -to led[5]
set_location_assignment PIN_42  -to led[4]
set_location_assignment PIN_38  -to led[3]
set_location_assignment PIN_33  -to led[2]
set_location_assignment PIN_31  -to led[1]
set_location_assignment PIN_28  -to led[0]
```