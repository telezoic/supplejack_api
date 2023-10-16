# frozen_string_literal: true


class ConceptSchema
  include SupplejackApi::SchemaDefinition

  # Namespaces
  namespace :dcterms,     url: 'http://purl.org/dc/terms/'
  namespace :edm,         url: 'http://www.europeana.eu/schemas/edm/'
  namespace :foaf,        url: 'http://xmlns.com/foaf/0.1/'
  namespace :owl,         url: 'http://www.w3.org/2002/07/owl#'
  namespace :rdaGr2,      url: 'http://rdvocab.info/ElementsGr2/'
  namespace :rdf,         url: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
  namespace :rdfs,        url: 'http://www.w3.org/2000/01/rdf-schema#'
  namespace :skos,        url: 'http://www.w3.org/2004/02/skos/core#'
  namespace :xsd,         url: 'http://www.w3.org/2001/XMLSchema#'
  namespace :dc,          url: 'http://purl.org/dc/elements/1.1/'
  namespace :wgs84,       url: 'http://www.w3.org/2003/01/geo/wgs84_pos#'

  # Fields (SourceAuthority fields)
  string      :name
  string      :title
  string      :prefLabel
  string      :altLabel,                  multi_value: true
  datetime    :dateOfBirth
  datetime    :dateOfDeath
  string      :biographicalInformation
  string      :sameAs,                    multi_value: true
  string      :givenName
  string      :familyName
  integer     :birthYear
  integer     :deathYear
  string      :note
  integer     :latitude
  integer     :longitude
  string      :_mn_family_name
  string      :_mn_given_name
  string      :concept_id
  integer     :concept_score
  string      :internal_identifier
  string      :source_id
  string      :source_name
  string      :url
  string      :updated_at
  string      :created_at

  group :source_authorities
  group :reverse

  group :default do
    fields [
      :name,
      :title
    ]
  end

  group :verbose do
    fields [
      :name,
      :prefLabel,
      :altLabel,
      :dateOfBirth,
      :dateOfDeath,
      :biographicalInformation,
      :sameAs,
      :title
    ]
  end

  # Concept
  # field_options is required if your are storing the field
  model_field :name, field_options: { type: String }, search_as: [:fulltext], search_boost: 6, namespace: :foaf
  model_field :title, field_options: { type: String }, namespace: :dc
  model_field :prefLabel, field_options: { type: String }, namespace: :skos
  model_field :altLabel, field_options: { type: Array }, search_as: [:fulltext], search_boost: 2, namespace: :skos
  model_field :dateOfBirth, field_options: { type: Date }, namespace: :rdaGr2
  model_field :dateOfDeath, field_options: { type: Date }, namespace: :rdaGr2
  model_field :biographicalInformation, field_options: { type: String }, search_as: [:fulltext], search_boost: 1,  namespace: :rdaGr2
  model_field :sameAs, field_options: { type: Array }, namespace: :owl
  model_field :note, field_options: { type: String }, namespace: :wgs84
  model_field :latitude, field_options: { type: Integer }, namespace: :wgs84
  model_field :longitude, field_options: { type: Integer }, namespace: :wgs84
  model_field :type do
    store false
    search_as [:filter]
    type :string
    search_value do |concept|
      concept.concept_type
    end
  end

  # Use store: false to display the fields in the /schema
  model_field :date, store: false, namespace: :dc
  model_field :description, store: false, namespace: :dc
  model_field :agents, store: false, namespace: :edm
  model_field :source_authority do
    search_as [:filter]
    store false
    type :string
    multi_value true
    namespace :foaf
    search_value do |concept|
      concept.source_authorities.map(&:internal_identifier)
    end
  end
end
