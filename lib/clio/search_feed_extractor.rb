# encoding: utf-8
class SearchFeedExtractor < FeedExtractor
    def save_feedinfo
        response = client.request("feedinfo/#{context.clio.user}").
            merge('name' => context.search_request,
                'description' => "Поиск «#{context.search_request}» от имени #{context.clio.user}",
                'subscriptions' => nil,
                'subscribers' => nil,
                'search' => context.search_request,
                'type' => 'search'
            )
        File.write(context.json_path!("feedinfo.js"),
            response.to_json)
    end

    def extract_feed(params)
        client.request("search", params.merge(q: context.search_request))
    end
end

