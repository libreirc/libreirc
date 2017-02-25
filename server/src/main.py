from sanic import Sanic
from sanic.response import json

app = Sanic(__name__)

# Static file serving
#
# TODO: static file serving need to be used only in debug mode.
# See https://github.com/libreirc/libreirc/issues/8 for the further details.
app.static('/', './public/index.html')
app.static('*', './public')

app.run(host="0.0.0.0", port=4321)
