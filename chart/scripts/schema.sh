#!/usr/bin/env bash
set -euo pipefail

# Generate Helm chart schema from values.yaml with @param annotations
# This script creates values.schema.json for IDE validation and autocomplete

cd "$(dirname "$0")/.."

echo "🔧 Generating Helm chart schema..."
helm schema --no-additional-properties --indent 2

echo "📝 Post-processing schema for flexibility..."
# Fix overly restrictive schema for fields that need flexibility
jq '
  # Allow arbitrary annotations and labels
  (.properties.podAnnotations | select(. != null)) |= del(.additionalProperties) |
  (.properties.podLabels | select(. != null)) |= del(.additionalProperties) |

  # Allow flexible ingress annotations
  (.properties.ingress.properties.annotations | select(. != null)) |= del(.additionalProperties) |

  # Allow flexible service account annotations
  (.properties.serviceAccount.properties.annotations | select(. != null)) |= del(.additionalProperties) |

  # Allow flexible arrays for extensibility
  (.properties.env | select(. != null)) |= del(.items.additionalProperties) |
  (.properties.envFrom | select(. != null)) |= del(.items.additionalProperties) |

  # Allow flexible node selector
  (.properties.nodeSelector | select(. != null)) |= del(.additionalProperties) |

  # Allow flexible tolerations
  (.properties.tolerations | select(. != null)) |= del(.items.additionalProperties) |

  # Allow flexible affinity rules
  (.properties.affinity | select(. != null)) |= del(.additionalProperties) |

  # Ensure imagePullSecrets are strings (secret names)
  (.properties.imagePullSecrets.items | select(. != null)) = { "type": "string" } |

  # Allow keycloak subchart to have its own schema - recursively remove additionalProperties
  (.properties."keycloak" | select(. != null)) |= walk(if type == "object" and has("additionalProperties") then del(.additionalProperties) else . end)
' values.schema.json > values.schema.json.tmp && mv values.schema.json.tmp values.schema.json

echo "✅ Schema generated: values.schema.json"
echo "💡 Your IDE can now provide validation and autocomplete for values.yaml"
