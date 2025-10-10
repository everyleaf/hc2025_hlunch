OpenAI.configure do |config|
  config.uri_base = ENV.fetch("OPENAI_API_BASE", "http://localhost:1234/v1/")
  config.access_token = "dummy" # LM Studioはトークン不要だが設定は必須
  config.request_timeout = 240 # LLM生成は時間がかかるためタイムアウトを長めに
end
