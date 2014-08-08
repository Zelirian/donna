fs      = require 'fs'
path    = require 'path'

{inspect} = require 'util'
walkdir = require 'walkdir'
MetaDoc = require '../src/metadoc'
Parser  = require '../src/parser'
Metadata = require '../src/metadata'

{diff}    = require 'jsondiffpatch'
_         = require 'underscore'

CoffeeScript = require 'coffee-script'

require 'jasmine-focused'
require 'jasmine-json'

describe "Metadata", ->
  parser = null

  constructDelta = (filename, hasReferences = false) ->
    source = fs.readFileSync filename, 'utf8'

    parser.parseContent source, filename
    metadata = new Metadata({}, parser)
    metadata.generate(CoffeeScript.nodes(source))
    generated = MetaDoc.populateSlug({ files: {} }, filename, metadata)

    expected_filename = filename.replace(/\.coffee$/, '.json')
    expected = JSON.parse(fs.readFileSync(expected_filename, 'utf8'))

    expect(generated).toEqualJson(expected)

  beforeEach ->
    parser = new Parser({
      inputs: []
      output: ''
      extras: []
      readme: ''
      title: ''
      quiet: false
      private: true
      verbose: true
      metadata: true
      github: ''
    })

  describe "Classes", ->
    it 'understands descriptions', ->
      constructDelta("spec/metadata_templates/classes/basic_class.coffee")

    it 'understands class properties', ->
      constructDelta("spec/metadata_templates/classes/class_with_class_properties.coffee")

    it 'understands prototype properties', ->
      constructDelta("spec/metadata_templates/classes/class_with_prototype_properties.coffee")

    it 'understands comment sections properties', ->
      constructDelta("spec/metadata_templates/classes/class_with_comment_section.coffee")

    it 'selects the correct doc string for each function', ->
      constructDelta("spec/metadata_templates/classes/classes_with_similar_methods.coffee")

    it 'preserves comment indentation', ->
      constructDelta("spec/metadata_templates/classes/class_with_comment_indentation.coffee")

  describe "Exports", ->
    it 'understands basic exports', ->
      constructDelta("spec/metadata_templates/exports/basic_exports.coffee")

    it 'understands class exports', ->
      constructDelta("spec/metadata_templates/exports/class_exports.coffee")

  describe "Requires", ->
    it 'understands basic requires', ->
      constructDelta("spec/metadata_templates/requires/basic_requires.coffee")

    it 'understands multiple requires on a single line', ->
      constructDelta("spec/metadata_templates/requires/multiple_requires_single_line.coffee")

    it 'understands requires with a colon', ->
      constructDelta("spec/metadata_templates/requires/requires_with_colon.coffee")

    it 'understands importing', ->
      constructDelta("spec/metadata_templates/requires/references/buffer-patch.coffee")

  describe "A real package", ->
    packageJsonPath = null
    test_path = null

    beforeEach ->
      test_path = path.join("spec", "metadata_templates", "test_package")
      packageJsonPath = path.join(test_path, 'package.json')
      for file in fs.readdirSync(path.join(test_path, "src"))
        parser.parseFile path.join(test_path, "src", file)

    it "renders the package correctly", ->
      slug = MetaDoc.generateMetadataSlug(packageJsonPath, parser, {output: ""})

      expected_filename = path.join(test_path, 'test_metadata.json')
      expected = JSON.parse(fs.readFileSync(expected_filename, 'utf8'))

      expect(slug).toEqualJson expected
      expect(_.keys(slug.files)).not.toContain "./Gruntfile.coffee"
      expect(_.keys(slug.files)).not.toContain "./spec/text-buffer-spec.coffee"
