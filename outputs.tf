locals {
  export_as_organization_variable = {
    "acm_certificate_arn" = {
      hcl       = false
      sensitive = false
      value     = aws_acm_certificate.acm_certificate.arn
    }
    "hosting_zone_id" = {
      hcl       = false
      sensitive = false
      value     = aws_route53_zone.hosting_zone.id
    }
    "hosting_zone_name" = {
      hcl       = false
      sensitive = false
      value     = aws_route53_zone.hosting_zone.name
    }
  }
}

data "tfe_organization" "organization" {
  name = var.terraform_organization
}

data "tfe_variable_set" "variables" {
  name         = "variables"
  organization = data.tfe_organization.organization.name
}

resource "tfe_variable" "output_values" {
  for_each = local.export_as_organization_variable

  key             = each.key
  value           = each.value.hcl ? jsonencode(each.value.value) : tostring(each.value.value)
  category        = "terraform"
  description     = "${each.key} variable from the ${var.service} service"
  variable_set_id = data.tfe_variable_set.variables.id
  hcl             = each.value.hcl
  sensitive       = each.value.sensitive
}
