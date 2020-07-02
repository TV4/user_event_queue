defmodule UserEvent.User do
  defstruct [
    :accepted_cmore_terms,
    :accepted_fotbollskanalen_terms,
    :accepted_play_terms,
    :cmore_newsletter,
    :country_code,
    :email,
    :first_name,
    :generic_ads,
    :last_name,
    :no_ads,
    :user_id,
    :username,
    :year_of_birth,
    :zip_code
  ]

  @type t :: %__MODULE__{}

  def parse(params) do
    %__MODULE__{}
    |> Map.from_struct()
    |> Map.keys()
    |> Enum.reduce(%__MODULE__{}, fn key, user ->
      case Map.get(params, to_string(key)) do
        nil -> user
        value -> Map.put(user, key, value)
      end
    end)
  end

  def to_user_map(%__MODULE__{} = user) do
    user
    |> Map.from_struct()
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end
end
