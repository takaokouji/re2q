module Types
  class PlayerType < Types::BaseObject
    global_id_field :id
    field :name, String
  end
end
