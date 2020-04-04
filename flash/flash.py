#!/usr/bin/env python3

import socket
import argparse


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description = 'OTA-Flash-Tool for ESP - by Henry Thasler')
    apg_input = parser.add_argument_group('Connection')
    apg_input.add_argument("-H", "--host", help = "host")
    apg_input.add_argument("-p", "--port", type = int, help = "port", default=81)

    apg_output = parser.add_argument_group('Files')
    apg_output.add_argument('files', nargs='+', help = 'files to transfer (source:destination)')
    options = parser.parse_args()
