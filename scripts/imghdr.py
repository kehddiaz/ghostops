# Minimal imghdr stub so pybadges can import it on Python 3.13+
def what(file, h=None):
    # pybadges only uses this to sniff image types,
    # and since we’re emitting SVG, just return 'svg'
    return "svg"
