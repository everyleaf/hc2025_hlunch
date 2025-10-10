OpenAI.configure do |config|
  config.uri_base = ENV.fetch("OPENAI_API_BASE", "https://api.openai.com/v1/")
  config.access_token = ENV.fetch("OPENAI_API_KEY", "test-key") # テスト環境ではダミー値を使用
  config.request_timeout = 240 # LLM生成は時間がかかるためタイムアウトを長めに
end
