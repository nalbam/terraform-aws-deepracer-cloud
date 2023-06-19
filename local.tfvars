region                      = "us-east-1"
name                        = "dr-cloud"
instance_type               = "g5.8xlarge"
ami_id                      = "ami-0365f1c02d110fa96"
ebs_optimized               = true
volume_type                 = "gp3"
volume_size                 = "100"
iops                        = "3000"
throughput                  = "125"
delete_on_termination       = true
associate_public_ip_address = true
min                         = 0
max                         = 1
desired                     = 1
allow_ip_address = [ #"0.0.0.0/0",
  "96.245.253.208/32"
  # "39.117.14.79/32", # echo "$(curl -sL icanhazip.com)/32"
]
key_name                  = "turboracers-keypair"
bucket_name_prefix        = "sreenath-drfc" #use unique name prefix 
dr_world_name             = "AmericasGeneratedInclStart"
dr_model_base_name        = "baadal-tf-1"
ssm_parameter_name_prefix = "/dr-sreenath"
