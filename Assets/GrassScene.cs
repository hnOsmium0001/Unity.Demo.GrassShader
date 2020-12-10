using UnityEngine;

using Random = System.Random;

[ExecuteInEditMode]
public class GrassScene : MonoBehaviour
{
    public Vector2 size = new Vector2(10, 10);

    [Range(1, 20)]
    public float density = 9.0f;

    private Mesh grassMesh;
    private Mesh terrainMesh;

    void Start()
    {
        var meshWidth = (int)(size.x * density);
        var meshHeight = (int)(size.y * density);
        var offsetX = size.x / 2;
        var offsetY = size.y / 2;

        var random = new Random();
        var vertices = new Vector3[meshWidth * meshHeight];
        var indices = new int[meshWidth * meshHeight];
        for (int y = 0; y < meshHeight; y++)
        {
            for (int x = 0; x < meshWidth; x++)
            {
                int i = y * meshWidth + x;
                var pos = new Vector3(
                    x + (float) random.NextDouble() - 0.5f, 
                    0.0f,
                    y + (float) random.NextDouble() - 0.5f);

                vertices[i] = new Vector3(
                    pos.x / meshWidth * size.x - offsetX,
                    pos.y,
                    pos.z / meshHeight * size.y - offsetY);
                indices[i] = i;
            }
        }
        
        grassMesh = new Mesh();
        grassMesh.vertices = vertices;
        grassMesh.SetIndices(indices, MeshTopology.Points, 0);
        var grass = GameObject.Find("Grass");
        grass.GetComponent<MeshFilter>().sharedMesh = grassMesh;

        terrainMesh = new Mesh();
        // TODO
        var terrain = GameObject.Find("Terrain");
        terrain.GetComponent<MeshFilter>().sharedMesh = terrainMesh;
    }

    void Update()
    {
    }
}
