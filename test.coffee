Tinytest.add 'example', (test) ->
  test.equal true, true
  str = """
  	Google spins out Project Tango from its Advanced Technology and Projects group - 
	At the moment, it’s not quite clear what’s happening to Project Tango, Google’s ambitious plan to 
	put 3D mapping technology inside your smartphone. Today Google’s Advanced Technology and Projects 
	group (ATAP) announced that, “after two fast-paced years in ATAP, and many technical successes, the 
	Tango team is transitioning from ATAP to a new home within Google.”
  """
  tags = Tags.findFrom str
  test.equal tags, ["google","spins","project","tango","advanced","technology","group","moment","clear","happening","ambitious","plan","mapping","inside","smartphone","today","atap","announced","two","paced","years","technical","successes","team","transitioning","within"]