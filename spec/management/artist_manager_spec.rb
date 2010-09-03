require "spec"
require "sevendigital"

describe "ArtistManager" do

  before do
    @client = stub(Sevendigital::Client)
    @client.stub!(:operator).and_return(mock(Sevendigital::ApiOperator))
    @artist_manager = Sevendigital::ArtistManager.new(@client)
  end

  it "get_details should call artist/details api method and return digested artist" do
    an_artist_id = 123
    an_artist = Sevendigital::Artist.new(@client)
    an_api_response = fake_api_response("release/details")

    mock_client_digestor(@client, :artist_digestor) \
          .should_receive(:from_xml).with(an_api_response.content.artist).and_return(an_artist)

    @client.operator.should_receive(:call_api) { |api_request|
      api_request.api_method.should == "artist/details"
      api_request.parameters[:artistId].should  == an_artist_id
      an_api_response
    }

    artist = @artist_manager.get_details(an_artist_id)
    artist.should == an_artist
	end

  it "get_releases should call artist/releases api method and return list of digested releases" do
    an_artist_id = 123
    a_list_of_releases = [Sevendigital::Release.new(@client), Sevendigital::Release.new(@client)]
    an_api_response = fake_api_response("artist/releases")

    mock_client_digestor(@client, :release_digestor) \
         .should_receive(:list_from_xml).with(an_api_response.content.releases).and_return(a_list_of_releases)

    @client.operator.should_receive(:call_api) { |api_request|
      api_request.api_method.should == "artist/releases"
      api_request.parameters[:artistId].should  == an_artist_id
      an_api_response
    }

    releases = @artist_manager.get_releases(an_artist_id)
    releases.should == a_list_of_releases
  end

  it "get_top_tracks should call artist/toptracks method and digest the returned list of tracks" do
    an_artist_id = 123
    a_top_tracks_list = [Sevendigital::Track.new(@client)]
    an_api_response = fake_api_response("artist/toptracks")
    
    mock_client_digestor(@client, :track_digestor) \
        .should_receive(:list_from_xml).with(an_api_response.content.tracks).and_return(a_top_tracks_list)

    @client.operator.should_receive(:call_api) { |api_request|
      api_request.api_method.should == "artist/toptracks"
      api_request.parameters[:artistId].should  == an_artist_id
      an_api_response
    }

    tracks = @artist_manager.get_top_tracks(an_artist_id)
    tracks.should == a_top_tracks_list

  end

  it "get_similar should call artist/similar method and digest the returned list of artists" do
    an_artist_id = 123
    a_similar_artists_list = [Sevendigital::Artist.new(@client), Sevendigital::Artist.new(@client)]
    an_api_response = fake_api_response("artist/similar")

    mock_client_digestor(@client, :artist_digestor) \
        .should_receive(:list_from_xml).with(an_api_response.content.artists).and_return(a_similar_artists_list)

    @client.operator.should_receive(:call_api) { |api_request|
      api_request.api_method.should == "artist/similar"
      api_request.parameters[:artistId].should  == an_artist_id
      an_api_response
    }

    artists = @artist_manager.get_similar(an_artist_id)
    artists.should == a_similar_artists_list

  end

  it "get_top_by_tag should call artist/byTag/top api method and digest the nested artist list from response" do

    tags = "alternative-indie"
    api_response = fake_api_response("artist/byTag/top")
    an_artist_list = []

    mock_client_digestor(@client, :artist_digestor) \
      .should_receive(:nested_list_from_xml) \
      .with(api_response.content.tagged_results, :tagged_item, :tagged_results) \
      .and_return(an_artist_list)

    @client.operator.should_receive(:call_api) { |api_request|
       api_request.api_method.should == "artist/byTag/top"
       api_request.parameters[:tags].should == tags
       api_response
    }

    releases = @artist_manager.get_top_by_tag(tags)
    releases.should == an_artist_list

  end

end