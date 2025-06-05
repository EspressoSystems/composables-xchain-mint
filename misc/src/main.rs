use alloy::providers::{Provider, ProviderBuilder};
use alloy::transports::http::reqwest::Url;

#[tokio::main]
async fn main() {
    // TODO ED properly check for errors; clean up
    let rpc_url = Url::parse("http://127.0.0.1:8545").unwrap();
    let provider = ProviderBuilder::new().connect_http(rpc_url);

    let block_number = provider.get_block_number().await;
    println!("Block height: {:?}", block_number);
}
