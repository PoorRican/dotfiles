local schemas = require("schemastore").yaml.schemas()

-- SchemaStore supplies kustomization.yaml; scope the generic Kubernetes schema
-- to conventional manifest directories so unrelated YAML is not misdiagnosed.
schemas.kubernetes = {
	"**/k3s/**/*.yaml",
	"**/k3s/**/*.yml",
	"**/k8s/**/*.yaml",
	"**/k8s/**/*.yml",
	"**/kubernetes/**/*.yaml",
	"**/kubernetes/**/*.yml",
	"**/kustomize/**/*.yaml",
	"**/kustomize/**/*.yml",
	"**/manifests/**/*.yaml",
	"**/manifests/**/*.yml",
}

return {
	settings = {
		yaml = {
			completion = true,
			hover = true,
			schemaStore = {
				enable = false,
				url = "",
			},
			schemas = schemas,
			validate = true,
		},
	},
}
