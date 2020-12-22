extends Node
class_name Level

var slug
var title
var description
var congrats
var cards
var repos = {}

# The path is an outer path.
func load(path):
	var parts = path.split("/")
	slug = parts[parts.size()-1]
	
	var dir = Directory.new()
	if dir.file_exists(path):
		# This is a new-style level.
		var config = helpers.parse(path)
		
		title = config.get("title", slug)
		description = config.get("description", "(no description)")
		congrats = config.get("congrats", "Good job, you solved the level!\n\nFeel free to try a few more things or click 'Next level'.")
		cards = Array(config.get("cards", "").split(" "))
		if cards == [""]:
			cards = []
		
		var keys = config.keys()
		var repo_setups = []
		for k in keys:
			if k.begins_with("setup"):
				repo_setups.push_back(k)
		var repo_wins = []
		for k in keys:
			if k.begins_with("win"):
				repo_wins.push_back(k)
				
		for k in repo_setups:
			var repo
			if " " in k: # [setup yours]
				repo = Array(k.split(" "))[1]
			else:
				repo = "yours"
			if not repos.has(repo):
				repos[repo] = LevelRepo.new()
			repos[repo].setup_commands = config[k]
		
		for k in repo_wins:
			var repo
			if " " in k:
				repo = Array(k.split(" "))[1]
			else:
				repo = "yours"
			
			var description = "Goal"
			for line in Array(config[k].split("\n")):
				if line.length() > 0 and line[0] == "#":
					description = line.substr(1)
				else:
					if not repos[repo].win_conditions.has(description):
						repos[repo].win_conditions[description] = ""
					repos[repo].win_conditions[description] += line+"\n"
				
#			for desc in repos[repo].win_conditions:
#				print("Desc: " + desc)
#				print("Commands: " + repos[repo].win_conditions[desc])
	else:
		helpers.crash("Level %s does not exist." % path)
	
	for repo in repos:
		repos[repo].path = game.tmp_prefix+"repos/%s/" % repo
		repos[repo].slug = repo
	
	# Surround all lines indented with four spaces with [code] tags.
	var monospace_regex = RegEx.new()
	monospace_regex.compile("\\n    ([^\\n]*)")
	description = monospace_regex.sub(description, "\n      [code]$1[/code]", true)

func construct():
	for r in repos:
		var repo = repos[r]
		# We're actually destroying stuff here.
		# Make sure that active_repository is in a temporary directory.
		helpers.careful_delete(repo.path)
		
		game.global_shell.run("mkdir '%s'" % repo.path)
		game.global_shell.cd(repo.path)
		game.global_shell.run("git init")
		game.global_shell.run("git symbolic-ref HEAD refs/heads/main")
		
		# Add other repos as remotes.
		for r2 in repos:
			if r == r2:
				continue
			game.global_shell.run("git remote add %s %s" % [r2, repos[r2].path])
		
		# Allow receiving a push of the checked-out branch.
		game.global_shell.run("git config receive.denyCurrentBranch ignore")
		
	for r in repos:
		var repo = repos[r]
		game.global_shell.cd(repo.path)
		game.global_shell.run(repo.setup_commands)

func check_win():
	var won = true
	var any_checked = false
	for r in repos:
		var repo = repos[r]
		if repo.win_conditions.size() > 0:
			any_checked = true
			game.global_shell.cd(repo.path)
			for description in repo.win_conditions:
				var commands = repo.win_conditions[description]
				if not game.global_shell.run("function win { %s\n}; win 2>/dev/null >/dev/null && echo yes || echo no" % commands) == "yes\n":
					won = false
	return won and any_checked
