local Csmoon_Effects = {}
Csmoon_Effects.version = "1.0.0"
Csmoon_Effects.effects = {}
Csmoon_Effects.templates = {}

local generated_code = {
  usings = {
    "System",
    "System.Collections.Generic",
    "System.Numerics",
    "UnityEngine",
    "System.Linq"
  },
  effects = {},
  composites = {}
}

local function luaToCS(value)
  if type(value) == "string" then
    return '"' .. value .. '"'
  elseif type(value) == "number" then
    if math.floor(value) == value then
      return tostring(value)
    else
      return tostring(value) .. "f"
    end
  elseif type(value) == "boolean" then
    return value and "true" or "false"
  elseif type(value) == "table" then
    if value.x and value.y then
      return string.format("new Vector2(%sf, %sf)", value.x, value.y)
    elseif value.r and value.g and value.b then
      local a = value.a or 1
      return string.format("new Color(%sf, %sf, %sf, %sf)", value.r, value.g, value.b, a)
    else
      local result = "new { "
      for k, v in pairs(value) do
        result = result .. k .. " = " .. luaToCS(v) .. ", "
      end
      result = result:sub(1, -3) .. " }"
      return result
    end
  else
    return "null"
  end
end

local function addEffect(effectType, params)
  local effect = {
    type = effectType,
    id = params.id or ("effect_" .. #Csmoon_Effects.effects + 1),
    params = params
  }
  
  table.insert(Csmoon_Effects.effects, effect)
  return effect
end

function Csmoon_Effects.createParticles(params)
  assert(type(params) == "table", "Parameters must be a table")
  
  local cs_code = [[
  var ${id} = new ParticleSystem()
  {
      Name = ${name},
      MaxParticles = ${maxParticles},
      EmissionRate = ${emissionRate},
      Lifetime = ${lifetime},
      StartSize = ${startSize},
      EndSize = ${endSize},
      StartColor = ${startColor},
      EndColor = ${endColor},
      Texture = ${texture},
      Gravity = ${gravity},
      Position = ${position},
      Velocity = ${velocity},
      VelocityVariation = ${velocityVariation}
  };
  effects.Add(${id});
  ]]
  
  params.name = params.name or "Particles"
  params.maxParticles = params.maxParticles or 100
  params.emissionRate = params.emissionRate or 10
  params.lifetime = params.lifetime or 2
  params.startSize = params.startSize or 1
  params.endSize = params.endSize or 0.1
  params.startColor = params.startColor or {r=1, g=1, b=1, a=1}
  params.endColor = params.endColor or {r=1, g=1, b=1, a=0}
  params.texture = params.texture or "default"
  params.gravity = params.gravity or {x=0, y=-9.8}
  params.position = params.position or {x=0, y=0}
  params.velocity = params.velocity or {x=0, y=1}
  params.velocityVariation = params.velocityVariation or 0.5
  
  local effect = addEffect("particles", params)
  
  for k, v in pairs(params) do
    cs_code = cs_code:gsub("${" .. k .. "}", luaToCS(v))
  end
  cs_code = cs_code:gsub("${id}", effect.id)
  
  table.insert(generated_code.effects, cs_code)
  
  return effect
end

function Csmoon_Effects.createLight(params)
  assert(type(params) == "table", "Parameters must be a table")
  
  local cs_code = [[
  var ${id} = new LightEffect()
  {
      Type = LightType.${type},
      Color = ${color},
      Intensity = ${intensity},
      Range = ${range},
      Position = ${position},
      Falloff = ${falloff},
      CastShadows = ${castShadows}
  };
  effects.Add(${id});
  ]]
  
  params.type = params.type or "Point"
  params.color = params.color or {r=1, g=1, b=1}
  params.intensity = params.intensity or 1
  params.range = params.range or 5
  params.position = params.position or {x=0, y=0}
  params.falloff = params.falloff or 1
  params.castShadows = params.castShadows ~= false
  
  local effect = addEffect("light", params)
  
  for k, v in pairs(params) do
    cs_code = cs_code:gsub("${" .. k .. "}", luaToCS(v))
  end
  cs_code = cs_code:gsub("${id}", effect.id)
  
  table.insert(generated_code.effects, cs_code)
  
  return effect
end

function Csmoon_Effects.createFilter(params)
  assert(type(params) == "table", "Parameters must be a table")
  
  local cs_code = [[
  var ${id} = new FilterEffect()
  {
      Type = FilterType.${type},
      Strength = ${strength},
      Color = ${color},
      Radius = ${radius},
      Center = ${center},
      Parameters = ${parameters}
  };
  effects.Add(${id});
  ]]
  
  params.type = params.type or "Blur"
  params.strength = params.strength or 1
  params.color = params.color or {r=1, g=1, b=1}
  params.radius = params.radius or 5
  params.center = params.center or {x=0.5, y=0.5}
  params.parameters = params.parameters or {}
  
  local effect = addEffect("filter", params)
  
  for k, v in pairs(params) do
    cs_code = cs_code:gsub("${" .. k .. "}", luaToCS(v))
  end
  cs_code = cs_code:gsub("${id}", effect.id)
  
  table.insert(generated_code.effects, cs_code)
  
  return effect
end

function Csmoon_Effects.createAnimation(params)
  assert(type(params) == "table", "Parameters must be a table")
  
  local cs_code = [[
  var ${id} = new AnimationEffect()
  {
      Duration = ${duration},
      Loop = ${loop},
      Target = ${target},
      KeyFrames = new List<KeyFrame>()
  };
  
  ${keyframes}
  
  effects.Add(${id});
  ]]
  
  local keyframes_code = ""
  if params.keyframes and #params.keyframes > 0 then
    for i, kf in ipairs(params.keyframes) do
      keyframes_code = keyframes_code .. string.format([[
      ${id}.KeyFrames.Add(new KeyFrame() {
          Time = %sf,
          Value = %s,
          EasingFunction = EasingFunction.%s
      });
      ]], kf.time, luaToCS(kf.value), kf.easing or "Linear")
    end
  end
  
  params.duration = params.duration or 1
  params.loop = params.loop ~= false
  params.target = params.target or "Position"
  params.keyframes = params.keyframes or {}
  
  local effect = addEffect("animation", params)
  
  for k, v in pairs(params) do
    if k ~= "keyframes" then
      cs_code = cs_code:gsub("${" .. k .. "}", luaToCS(v))
    end
  end
  cs_code = cs_code:gsub("${keyframes}", keyframes_code)
  cs_code = cs_code:gsub("${id}", effect.id)
  
  table.insert(generated_code.effects, cs_code)
  
  return effect
end

function Csmoon_Effects.createTransition(params)
  assert(type(params) == "table", "Parameters must be a table")
  
  local cs_code = [[
  var ${id} = new TransitionEffect()
  {
      Duration = ${duration},
      Type = TransitionType.${type},
      EasingFunction = EasingFunction.${easing},
      FromValue = ${from},
      ToValue = ${to},
      Target = ${target}
  };
  effects.Add(${id});
  ]]
  
  params.duration = params.duration or 1
  params.type = params.type or "Fade"
  params.easing = params.easing or "Linear"
  params.from = params.from or 0
  params.to = params.to or 1
  params.target = params.target or "Alpha"
  
  local effect = addEffect("transition", params)
  
  for k, v in pairs(params) do
    cs_code = cs_code:gsub("${" .. k .. "}", luaToCS(v))
  end
  cs_code = cs_code:gsub("${id}", effect.id)
  
  table.insert(generated_code.effects, cs_code)
  
  return effect
end

function Csmoon_Effects.composeEffects(params)
  assert(type(params) == "table", "Parameters must be a table")
  assert(type(params.effects) == "table" and #params.effects > 0, "Must provide at least one effect to compose")
  
  local cs_code = [[
  var ${id} = new CompositeEffect()
  {
      Name = ${name},
      BlendMode = BlendMode.${blendMode}
  };
  
  ${effect_refs}
  
  effects.Add(${id});
  ]]
  
  local effect_refs = ""
  for i, effect in ipairs(params.effects) do
    effect_refs = effect_refs .. string.format("  ${id}.AddEffect(%s);\n", effect.id)
  end
  
  params.name = params.name or "CompositeEffect"
  params.blendMode = params.blendMode or "Normal"
  
  local effect = addEffect("composite", params)
  
  for k, v in pairs(params) do
    if k ~= "effects" then
      cs_code = cs_code:gsub("${" .. k .. "}", luaToCS(v))
    end
  end
  cs_code = cs_code:gsub("${effect_refs}", effect_refs)
  cs_code = cs_code:gsub("${id}", effect.id)
  
  table.insert(generated_code.composites, cs_code)
  
  return effect
end

function Csmoon_Effects.generateCode()
  local result = "// Code generated by Csmoon_Effects v" .. Csmoon_Effects.version .. "\n\n"
  
  for _, using in ipairs(generated_code.usings) do
    result = result .. "using " .. using .. ";\n"
  end
  
  result = result .. [[

namespace Csmoon_Effects.Generated
{
    public class GeneratedEffects
    {
        public static List<IVisualEffect> CreateEffects()
        {
            var effects = new List<IVisualEffect>();
            
]]
  
  for _, code in ipairs(generated_code.effects) do
    result = result .. code .. "\n"
  end
  
  for _, code in ipairs(generated_code.composites) do
    result = result .. code .. "\n"
  end
  
  result = result .. [[
            return effects;
        }
    }
}
]]
  
  return result
end

function Csmoon_Effects.saveToFile(filename)
  local file = io.open(filename, "w")
  if not file then
    return false, "Could not open file for writing"
  end
  
  file:write(Csmoon_Effects.generateCode())
  file:close()
  
  return true
end

Csmoon_Effects.templates.explosionParticles = function(x, y, scale)
  scale = scale or 1
  return Csmoon_Effects.createParticles({
    name = "Explosion",
    maxParticles = 100 * scale,
    emissionRate = 50,
    lifetime = 1.5,
    startSize = 0.5 * scale,
    endSize = 0.1 * scale,
    startColor = {r=1, g=0.7, b=0.2, a=1},
    endColor = {r=0.8, g=0.3, b=0.1, a=0},
    texture = "explosion",
    gravity = {x=0, y=-1},
    position = {x=x or 0, y=y or 0},
    velocity = {x=0, y=0},
    velocityVariation = 5 * scale
  })
end

Csmoon_Effects.templates.pulsingLight = function(x, y, color, frequency)
  local light = Csmoon_Effects.createLight({
    type = "Point",
    color = color or {r=1, g=1, b=1},
    intensity = 1,
    range = 5,
    position = {x=x or 0, y=y or 0},
    falloff = 1,
    castShadows = true
  })
  
  local animation = Csmoon_Effects.createAnimation({
    duration = frequency or 2,
    loop = true,
    target = "Intensity",
    keyframes = {
      {time = 0, value = 1, easing = "QuadInOut"},
      {time = 0.5, value = 2.5, easing = "QuadInOut"},
      {time = 1, value = 1, easing = "QuadInOut"}
    }
  })
  
  return Csmoon_Effects.composeEffects({
    name = "PulsingLight",
    effects = {light, animation},
    blendMode = "Normal"
  })
end

return Csmoon_Effects
