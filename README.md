# Verilog credit card validator and identifier
This is an implementation of a credit/debit card validator using the [Luhn Algorithm](https://en.wikipedia.org/wiki/Luhn_algorithm) in Verilog. Using the [BIN number](https://en.wikipedia.org/wiki/Payment_card_number#Issuer_identification_number_(IIN)) of the inputted card, it also identifies the associated:
- Bank name (Bank of Montreal, Royal Bank of Canada, etc.)
- Card type (debit/credit)
- Card brand (Mastercard, VISA, American Express, etc.)
- Card level (Standard, Premium, Business, etc.)

This project was designed for use with the [DE1-SOC FPGA development board](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=836). It was written by Matthew Kong and Darman Ahmad at the University of Toronto for ECE241.

---

## Photos of the program
Shown below is the screen that displays when a valid card number is entered. The bank name, card type, card level, and card brand are displayed. Note that the card number displayed is purely for demonstration purposes, and is not a valid card number.

![photo](https://github.com/HynixCJR/ece241_project/blob/main/readme_photos/bg_valid.jpg)

Shown below is the screen that displays when no card number has been entered yet.

![photo](https://github.com/HynixCJR/ece241_project/blob/main/readme_photos/bg_no_numbers.jpg)

Shown below is a photo of the program running on a DE1-SOC FPGA board with VGA output. Note that the card number displayed is purely for demonstration purposes, and is not a valid card number.

![photo](https://github.com/HynixCJR/ece241_project/blob/main/readme_photos/demo.jpeg)

---
## Supported cards
The program can validate both IDs that have a total length of 16 digits, given that the IDs follow the Luhn Algorithm for verification. This includes almost all credit and debit cards, as well as 16-digit IMEI numbers. The algorithm itself also works for Canadian Social Insurance Numbers (SINs), United States Postal Service package tracking numbers, and Swedish Corporate Identity Numbers - among many other IDs; however, this program must be modified to use a different-length shift register to accomodate for number lengths other than 16 digits.

The payment card identification supports debit and credit cards from 59 different banks in Canada, including:
- TD CANADA TRUST
- SCOTIABANK
- CIBC
- RBC
- BMO
- IKEA (yes, I'm not joking)

...among many other banks. The full Excel file of each compatible BIN number and their associated information can be found here. This was scraped from the Canadian page of https://binlist.io/country/canada/.


---
## Compiling and running

This program was only tested on the [DE1-SOC FPGA development board](https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=836), connected to a VGA monitor and PS/2 keyboard. To compile it, you must import the correct DE1-SOC pin assignments. The top module is called [main](main.v).
