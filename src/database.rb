require 'google/cloud/firestore'
require './json_definition'

class Database
  attr_reader :store

  def initialize
    @store = Google::Cloud::Firestore.new project_id: PROJECT_ID
  end

  def read_schedule(handle, semester)
    collection = @store.col "students"
    doc = collection.doc handle
    data = doc.get.data
    return nil if data.nil? or not data.has_key? :semesters

    Hash[CurrentCalendar.definition.blocks.map do |block|
      [block, data[:semesters][semester.to_s.to_sym][block.to_sym]]
    end]
  end

  def register_association(user_id, handle)
    collection = @store.col "students"
    doc = collection.doc(handle)

    doc.set({discord_id: user_id})
  end

  def associated_handle(user_id)
    collection = @store.col "students"
    query = collection.where "discord_id", :eql, user_id.to_s

    query.get do |document|
      return document.document_id
    end

    nil
  end

  def is_verified_guild?(id)
    @store.doc('discord/verified_guilds').get.data[:ids].include? id.to_s
  end

  private

  PROJECT_ID = 'prematch-db'.freeze
end