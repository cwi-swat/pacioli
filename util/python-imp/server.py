import web, os

# NOTE: this script can only be called from inside this directory, because the
# path to the database and the static folder are hard-coded.

class graph:
	def GET(self, method, count):
		web.header("Content-Type", "image/svg+xml")
		data = os.popen("python generate_graph.py ../import.db %s | %s -Tsvg" % (count, method)).read()

		return data

class index:
	def GET(self):
		raise web.seeother('/static/index.html')
        
urls = (
	'/', 'index',
	'/graph/([a-z]+)/(.+)', 'graph'
	)
app = web.application(urls, globals())

if __name__ == "__main__":
	app.run()
