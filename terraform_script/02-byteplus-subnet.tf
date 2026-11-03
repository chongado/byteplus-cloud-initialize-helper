resource "bytepluscc_vpc_subnet" "public_subnet_1a" {
  vpc_id      = bytepluscc_vpc_vpc.vpc.id
  cidr_block  = local.public_subnet_1a
  zone_id     = local.zone_az_a
  subnet_name = "${local.resource_prefix}-public-subnet-1a"


  tags = concat(local.default_byteplus_tags, [
    {
      key   = "RESOURCE_NAME"
      value = "${local.resource_prefix}-public-subnet-1a"
    },
    {
      key   = "ZONE"
      value = "public"
    },
    {
      key   = "AZ"
      value = "1a"
    }
  ])

  depends_on = [
    time_sleep.vpc_ready
  ]
}

resource "bytepluscc_vpc_subnet" "public_subnet_1b" {
  vpc_id      = bytepluscc_vpc_vpc.vpc.id
  cidr_block  = local.public_subnet_1b
  zone_id     = local.zone_az_b
  subnet_name = "${local.resource_prefix}-public-subnet-1b"


  tags = concat(local.default_byteplus_tags, [
    {
      key   = "RESOURCE_NAME"
      value = "${local.resource_prefix}-public-subnet-1b"
    },
    {
      key   = "ZONE"
      value = "public"
    },
    {
      key   = "AZ"
      value = "1b"
    }
  ])

  depends_on = [
    time_sleep.vpc_ready,
    bytepluscc_vpc_vpc.vpc
  ]
}

resource "bytepluscc_vpc_subnet" "public_subnet_1c" {
  vpc_id      = bytepluscc_vpc_vpc.vpc.id
  cidr_block  = local.public_subnet_1c
  zone_id     = local.zone_az_c
  subnet_name = "${local.resource_prefix}-public-subnet-1c"


  tags = concat(local.default_byteplus_tags, [
    {
      key   = "RESOURCE_NAME"
      value = "${local.resource_prefix}-public-subnet-1c"
    },
    {
      key   = "ZONE"
      value = "public"
    },
    {
      key   = "AZ"
      value = "1c"
    }
  ])
  depends_on = [time_sleep.vpc_ready]
}

resource "bytepluscc_vpc_subnet" "private_subnet_1a" {
  vpc_id      = bytepluscc_vpc_vpc.vpc.id
  cidr_block  = local.private_subnet_1a
  zone_id     = local.zone_az_a
  subnet_name = "${local.resource_prefix}-private-subnet-1a"


  tags = concat(local.default_byteplus_tags, [
    {
      key   = "RESOURCE_NAME"
      value = "${local.resource_prefix}-private-subnet-1a"
    },
    {
      key   = "ZONE"
      value = "private"
    },
    {
      key   = "AZ"
      value = "1a"
    }
  ])
  depends_on = [time_sleep.vpc_ready]
}

resource "bytepluscc_vpc_subnet" "private_subnet_1b" {
  vpc_id      = bytepluscc_vpc_vpc.vpc.id
  cidr_block  = local.private_subnet_1b
  zone_id     = local.zone_az_b
  subnet_name = "${local.resource_prefix}-private-subnet-1b"


  tags = concat(local.default_byteplus_tags, [
    {
      key   = "RESOURCE_NAME"
      value = "${local.resource_prefix}-private-subnet-1b"
    },
    {
      key   = "ZONE"
      value = "private"
    },
    {
      key   = "AZ"
      value = "1b"
    }
  ])
  depends_on = [time_sleep.vpc_ready]
}

resource "bytepluscc_vpc_subnet" "private_subnet_1c" {
  vpc_id      = bytepluscc_vpc_vpc.vpc.id
  cidr_block  = local.private_subnet_1c
  zone_id     = local.zone_az_c
  subnet_name = "${local.resource_prefix}-private-subnet-1c"


  tags = concat(local.default_byteplus_tags, [
    {
      key   = "RESOURCE_NAME"
      value = "${local.resource_prefix}-private-subnet-1c"
    },
    {
      key   = "ZONE"
      value = "private"
    },
    {
      key   = "AZ"
      value = "1c"
    }
  ])
  depends_on = [time_sleep.vpc_ready]
}

resource "time_sleep" "wait_after_subnets" {
  create_duration = "60s"

  depends_on = [
    bytepluscc_vpc_subnet.public_subnet_1a,
    bytepluscc_vpc_subnet.public_subnet_1b,
    bytepluscc_vpc_subnet.public_subnet_1c,
    bytepluscc_vpc_subnet.private_subnet_1a,
    bytepluscc_vpc_subnet.private_subnet_1b,
    bytepluscc_vpc_subnet.private_subnet_1c,
  ]
}

