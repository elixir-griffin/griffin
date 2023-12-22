defmodule GriffinSSG.Plugin.CollectionsTest do
  use ExUnit.Case, async: true

  alias GriffinSSG.Plugin.Collections

  describe "init/1" do
    test "returns successfully with an empty config" do
      assert {:ok, %{}} == Collections.init(%{}, collections: %{})
    end

    test "returns successfully with a properly configured collection" do
      config = %{
        tags: %{
          permalink: "/tags/",
          list_layout: "list_tags",
          show_layout: "show_tag"
        }
      }

      assert {:ok, %{state: ^config}} = Collections.init(%{}, collections: config)
    end

    test "returns successfully with multiple collections" do
      config = %{
        tags: %{
          permalink: "/tags/",
          list_layout: "list_tags",
          show_layout: "show_tag"
        },
        albums: %{
          permalink: "/albums/",
          list_layout: "list_albums",
          show_layout: "show_album"
        },
        genres: %{
          permalink: "/genres/",
          list_layout: "list_genres",
          show_layout: "show_genre"
        }
      }

      assert {:ok, %{state: ^config}} = Collections.init(%{}, collections: config)
    end

    test "returns an error if the config name for a collection is not an atom" do
      invalid_collection_names = ["tags", "my collection", [], %{}, ?a]

      for name <- invalid_collection_names do
        assert {:error, "expected an atom as the collection name, found " <> _} =
                 Collections.init(%{}, collections: %{name => %{}})
      end
    end

    test "returns an error if a collection's config is not a map" do
      invalid_collection_configs = [[], "config", ?a]

      for config <- invalid_collection_configs do
        assert {:error, "expected a map as the config for collection `tags`, found " <> _} =
                 Collections.init(%{}, collections: %{tags: config})
      end
    end

    test "returns an error if a collection's config does not contain all required options" do
      # missing permalink
      assert {:error, "config for collection `tags` is invalid, check all required opts"} =
               Collections.init(%{},
                 collections: %{
                   tags: %{
                     list_layout: "list_tags",
                     show_layout: "show_tag"
                   }
                 }
               )

      # missing list_layout
      assert {:error, "config for collection `tags` is invalid, check all required opts"} =
               Collections.init(%{},
                 collections: %{
                   tags: %{
                     permalink: "/tags/",
                     show_layout: "show_tag"
                   }
                 }
               )

      # missing show_layout
      assert {:error, "config for collection `tags` is invalid, check all required opts"} =
               Collections.init(%{},
                 collections: %{
                   tags: %{
                     permalink: "/tags/",
                     list_layout: "list_tags"
                   }
                 }
               )
    end
  end
end
