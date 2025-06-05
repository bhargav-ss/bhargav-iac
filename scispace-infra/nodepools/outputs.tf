output "karpenter_custom_nodepools_helm_release_name" {
  description = "The name of the Helm release for the general-purpose Karpenter nodepools."
  value       = helm_release.karpenter_custom_nodepools.name
}

output "tiptap_collab_nodepool_helm_release_name" {
  description = "The name of the Helm release for the Tiptap Collab Karpenter nodepool."
  value       = helm_release.tiptap_collab_nodepool.name
} 