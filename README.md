# Scent Shop

A simple desktop invoicing application for a perfume shop. Scent Shop
helps staff create customer invoices, calculate totals automatically,
save invoice records locally, and print receipts using supported thermal
printers.

## Project Overview

-   **Application type:** Desktop
-   **Target platforms:** Windows and macOS
-   **Technology:** Flutter
-   **Local database:** SQLite
-   **Currency:** PKR
-   **Receipt printing:** Thermal paper sizes of 58mm and 80mm, subject
    to printer-driver compatibility

## Main Features

-   Create customer invoices.
-   Search and select perfumes from the shop's price list.
-   Select an available perfume size.
-   Automatically fill the corresponding price.
-   Enter quantities and calculate line totals.
-   Calculate invoice subtotal and total.
-   Save invoices locally.
-   Print receipts.
-   View saved invoices and reprint them.

## Perfume Price List

The supplied `Price List.pdf` contains 268 catalog entries and these
size options:

  Size              Notes
  ----------------- --------------
  10ml              Includes box
  30ml              Includes box
  50ml              Includes box
  Tola (12ml)       Oil only
  Half Tola (6ml)   Oil only

Prices must be imported from the supplied price list. Do not manually
invent or change catalog prices.

## Invoice Template

The supplied `Template.pdf` is the design reference. It includes receipt
number, date, customer name (`Received From`), item, quantity, rate,
amount, subtotal, tax (shown as 0%), and total.

The supplied template currently displays a dollar sign, while the price
list uses PKR. The application is intended to use **PKR**; confirm the
final printed layout with the shop owner.

## Printing Notes

The app will provide 58mm and 80mm receipt layouts. Thermal printer
compatibility depends on the printer model, operating-system support,
and installed driver. Test the actual printer models before deployment;
support for every thermal printer cannot be guaranteed.

## Getting Started

### Requirements

-   Flutter SDK with Windows desktop support enabled.
-   Visual Studio on Windows with the **Desktop development with C++**
    workload.
-   For macOS builds, a Mac with the required Xcode development tools.

### Check the Flutter setup

``` bash
flutter doctor -v
```

### Create the project

``` bash
flutter create --platforms=windows,macos scent_shop
cd scent_shop
```

Build and validate the macOS application on a Mac with Xcode.

### Run on Windows

``` bash
flutter run -d windows
```

### Run on macOS

``` bash
flutter run -d macos
```

## Project Status

**Planning / initial development.** The requirements and reference PDFs
have been identified. The app, database, catalog import, invoice layout,
and printer integration still need to be implemented and tested.

## Development Principles

-   Keep the interface straightforward and easy for shop staff.
-   Use the supplied catalog and invoice template as the source of
    truth.
-   Validate quantities and prices before saving or printing.
-   Handle database and printing errors clearly.
-   Keep secrets and machine-specific settings out of source code.
-   Test calculations, invoice persistence, and printing before release.

## Reference Files

Place the supplied reference files in a project documentation folder:

``` text
docs/
├── Price List.pdf
└── Template.pdf
```

Add the shop logo to the assets folder when it is provided.
