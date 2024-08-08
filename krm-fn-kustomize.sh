#! /bin/sh

echo "krm-fn-kustomize" 1>&2
echo "Kustomize version: $(kustomize version)" 1>&2

d=$(mktemp -q --directory || (echo "Failed to create temp directory" >&2 && exit 1))
trap 'rm -rf -- "$d"' EXIT

cat - > "$d/input.yaml"

cmd=$(yq '.functionConfig.data.cmd // "kustomize build --output build.yaml"' "$d/input.yaml")

echo "Running: $cmd" 1>&2

kpt fn sink "$d/workdir" 1>&2 < "$d/input.yaml"

cd "$d/workdir" 1>&2

#kpt pkg tree 1>&2

eval "$cmd" 1>&2

kpt fn source
