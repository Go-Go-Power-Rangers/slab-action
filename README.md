# Slab-action

This action can be integrated in the workflow to automatically post release content in a new slab post.

The release should only contain markdown format (as when pressing generate new release on github).
The release *cant* translate images, so don't use em.

## Usage

    runs-on: ubuntu-latest
    steps:
      - name: this workflow creates/updates a on slab containing release information
        uses: Go-Go-Power-Rangers/slab-action@main
        with: 
          repo_name: ${{ github.event.repository.name }}
          repo_owner: ${{ github.repository_owner }}
          accessToken_slab: "${{ secrets.SLAB_TOKEN }}"
          accessToken_github: "bearer ${{ secrets.GITHUB_TOKEN }}"