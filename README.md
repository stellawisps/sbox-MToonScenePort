# sbox-MToon 2024

**Asset.Party link: https://sbox.game/stellawisps/toonshader**

Toon Shader with Global Illumination. Ported to s&amp;box (Source 2).

![sbox_mtoon_demo](https://user-images.githubusercontent.com/5277788/202857510-282e7438-6486-467f-b082-4c604cc1840c.png)

# Source Shaders
https://github.com/Santarh/MToon
https://github.com/yuna0x0/sbox-MToon

---

### ALL texture inputs must have at least a color or valid texture file input.
The shader will not output the correct result if **any** texture has no input at all.

If some texture inputs are unused, just fill them with the default color by clicking the "Change To Color" button.

Different texture inputs might have different default colors.

![sbox_mtoon_texture_notice](https://user-images.githubusercontent.com/5277788/202855018-1a9a751f-2341-4e51-b925-403226d568fa.png)

# Limitation

- Multi-pass rendering is not yet supported (sboxgame/issues#1067). Therefore, the outline pass has not been implemented yet.
- Engine built-in shadowing and depth prepass (Shadow Caster) is different from Unity. The shadow under direct light looks weird or dirty. Might need to port the shadow caster.

# Credits
yuna0x0 - Original repository I used to convert to new s&box shaders.
