resource "aws_key_pair" "env-dedicatedshards" {
  key_name   = "${var.envName}-dedicated-shards"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrbRRa/b+adNsL4BKVba1iqAqUXVfnHLqbVVyOrTlaStJw+COQKN5/KAKtxatpTCRtiSH3f/YEgZ5vsMCsYNzli9SdOyqQmagNrMGS6xO4bOGwmuudamrbaW/5zEwWxvpLR78qWSTKwnv3SNAifL1AU0Ju5tcNHOgLTuHfKCFFU2oClQFbQ/HQ2siZCwT2BnI1SniST11yu6gQRJhfPXCl2xHxPZ1AB91Qur03UteYydeTzshUencWoZTousKy/0CLLH+MLlm5VbxFpMqdxjIgkwzdVeNTu295jyh8v+N9t4GVQ5/sw49NV9CDmxCk2TosEH4HSohan/DiQrRc+yat FilevineShards"

}

resource "aws_key_pair" "dedicatedshards" {
  key_name   = "dedicated-shards"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCrbRRa/b+adNsL4BKVba1iqAqUXVfnHLqbVVyOrTlaStJw+COQKN5/KAKtxatpTCRtiSH3f/YEgZ5vsMCsYNzli9SdOyqQmagNrMGS6xO4bOGwmuudamrbaW/5zEwWxvpLR78qWSTKwnv3SNAifL1AU0Ju5tcNHOgLTuHfKCFFU2oClQFbQ/HQ2siZCwT2BnI1SniST11yu6gQRJhfPXCl2xHxPZ1AB91Qur03UteYydeTzshUencWoZTousKy/0CLLH+MLlm5VbxFpMqdxjIgkwzdVeNTu295jyh8v+N9t4GVQ5/sw49NV9CDmxCk2TosEH4HSohan/DiQrRc+yat FilevineShards"

}


