#!/usr/bin/env python3
#
# import sys
#
# from PIL import Image
#
# import pyinsane2
#
#
# def main():
#     steps = False
#
#     args = sys.argv[1:]
#     if len(args) <= 0 or args[0] == "-h" or args[0] == "--help":
#         print("Syntax:")
#         print("  %s [-s] <output file (JPG)>" % sys.argv[0])
#         print("")
#         print("Options:")
#         print("  -s : Generate intermediate images (may generate a lot of"
#               " images !)")
#         sys.exit(1)
#
#     for arg in args[:]:
#         if arg == "-s":
#             steps = True
#             args.remove(arg)
#
#     output_file = args[0]
#     print("Output file: %s" % output_file)
#
#     print("Looking for scanners ...")
#     devices = pyinsane2.get_devices()
#     if (len(devices) <= 0):
#         print("No scanner detected !")
#         sys.exit(1)
#     print("Devices detected:")
#     print("- " + "\n- ".join([str(d) for d in devices]))
#
#     print("")
#
#     device = devices[0]
#     print("Will use: %s" % str(device))
#
#     print("")
#
#     # For the possible resolutions, look at
#     #   device.options['resolution'].constraint
#     # It will either be:
#     # - None: unknown
#     # - a tuple: (min resolution, max resolution)
#     # - a list: [75, 150, 300, 600, 1200, ...]
#
#     pyinsane2.set_scanner_opt(device, 'source', ['ADF Duplex'])
#     pyinsane2.set_scanner_opt(device, 'resolution', [150])
#     try:
#         pyinsane2.maximize_scan_area(device)
#     except Exception as exc:
#         print("Failed to maximize scan area: {}".format(exc))
#     # Beware: Some scanner have "Lineart" or "Gray" as default mode
#     pyinsane2.set_scanner_opt(device, 'mode', ['Color'])
#
#     print("")
#
#     print("Scanning ...  ")
#     scan_session = device.scan(multiple=False)
#
#     if steps and scan_session.scan.expected_size[1] < 0:
#         print("Warning: requested step by step scan images, but"
#               " scanner didn't report the expected number of lines"
#               " in the final image --> can't do")
#         print("Step by step scan images won't be recorded")
#         steps = False
#
#     if steps:
#         last_line = 0
#         expected_size = scan_session.scan.expected_size
#         img = Image.new("RGB", expected_size, "#ff00ff")
#         sp = output_file.split(".")
#         steps_filename = (".".join(sp[:-1]), sp[-1])
#
#     try:
#         PROGRESSION_INDICATOR = ['|', '/', '-', '\\']
#         i = -1
#         while True:
#             i += 1
#             i %= len(PROGRESSION_INDICATOR)
#             sys.stdout.write("\b%s" % PROGRESSION_INDICATOR[i])
#             sys.stdout.flush()
#
#             scan_session.scan.read()
#
#             if steps:
#                 next_line = scan_session.scan.available_lines[1]
#                 if (next_line > last_line + 100):
#                     subimg = scan_session.scan.get_image(last_line, next_line)
#                     img.paste(subimg, (0, last_line))
#                     img.save("%s-%05d.%s" % (steps_filename[0], last_line,
#                                              steps_filename[1]), "TIFF")
#                     last_line = next_line
#     except EOFError:
#         pass
#
#     print("\b ")
#     print("Writing output file ...")
#     img = scan_session.images[0]
#     img.save(output_file, "TIFF")
#     print("Done")
#
#
# if __name__ == "__main__":
#     pyinsane2.init()
#     try:
#         main()
#     finally:
#         pyinsane2.exit()
#
# # #!/usr/bin/env python3

import os
import sys

import pyinsane2


def main(args):
    dstdir = args[0]

    devices = pyinsane2.get_devices()
    assert(len(devices) > 0)
    device = devices[0]

    print("Will use the scanner [%s](%s)"
          % (str(device), device.name))

    pyinsane2.set_scanner_opt(device, "source", ["ADF Duplex"])
    # Beware: Some scanner have "Lineart" or "Gray" as default mode
    pyinsane2.set_scanner_opt(device, "mode", ["Gray"])
    pyinsane2.set_scanner_opt(device, "resolution", [300])
    #pyinsane2.maximize_scan_area(device)

    # Note: If there is no page in the feeder, the behavior of device.scan()
    # is not guaranteed : It may raise StopIteration() immediately
    # or it may raise it when scan.read() is called
    try:
        scan_session = None
        #print device.read
        scan_session = device.scan(multiple=True)
        print("Scanning ...")
        while True:
            try:
                #print("still scanning")
                scan_session.scan.read()
            except EOFError:
                print("Got page %d" % (len(scan_session.images)))
                #images.append(scan_session.images[-1])
                # img = scan_session.images[-1]
                # imgpath = os.path.join(dstdir, "%d.tiff" %
                #                        (len(scan_session.images)))
                # img.save(imgpath)
    except StopIteration:
        if not scan_session:
            print("Document tray is not loaded.")
        else:
            print("Got %d pages" % len(scan_session.images))

if __name__ == "__main__":
    args = sys.argv[1:]
    if len(args) <= 0 or args[0][0] == '-':
        print("Usage:")
        print("  %s <dst directory>" % sys.argv[0])
        sys.exit(1)
    pyinsane2.init()
    try:
        main(args)
    finally:
        pyinsane2.exit()
