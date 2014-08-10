/*
 * Copyright (C) 2014 Sebastien Diot.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.blockwithme.reprica.skills

import com.blockwithme.meta.annotations.Bean
import com.blockwithme.meta.beans._Bean
import java.util.List
import java.util.Set
import java.util.Map
import static java.util.Objects.*
import javax.inject.Provider

/** A Filter specifies if an Effect is going to be taken into account when evaluating a Value. */
interface Filter {
	/** Returns true, if this Effect is going to be taken into account when evaluating a Value. */
	def boolean accept(Effect effect)
	/** Returns a new Filter, combining both Filters. */
	def Filter and(Filter other)
}

/** Base class for Filters. */
abstract class AbstractFilter implements Filter {
	/** Allows combining FIlters easily. */
	private static final class AndFilter extends AbstractFilter {
		Filter first
		Filter second
		/** Creates a new Filter instance, combining two existing FIlters. */
		new(Filter first, Filter second) {
			this.first = requireNonNull(first, "first")
			this.second = requireNonNull(second, "second")
		}
		/** {@inheritDoc} */
		override boolean accept(Effect effect) {
			first.accept(effect) && second.accept(effect)
		}
	}

	/** {@inheritDoc} */
	override final Filter and(Filter other) {
		new AndFilter(this, other)
	}
}

/**
 * An effect category groups Effects of the same type together.
 * The buffs debuffs are stackable if they pertain to different categories.
 */
enum EffectCategory {
	/** Simple buff to one, multiple or all stats (or debuffs) */
	Simple,
	/** Berserk or negative Berserk increasing or decreasing all stats besides def/res */
	Berserk,
	/**
	 * Bravery or cowardice which increase or decrease att and the value
	 * increases/decreases per turn until the effect timeouts
	 */
	Bravery,
	/**
	 * Euphoria/virus which increases all stats or decreases them per turn until
	 * the effect timeouts, and where if the euphoria is 50% / 5 turns the 50%
	 * will be reached turn 5 and not turn 1
	 */
	Euphoria
}

/** A Category groups Attributes of the same type together. */
enum AttributeCategory {
	/** Attributes that contribute to "attack" */
	Attack,
	/** Attributes that contribute to "defense" */
	Defense,
	/** All other attributes */
	Auxiliary
}

/** Base type of everything in this package */
@Bean
interface Root {
	// NOP
}

/** Marker interface, denoting objects that represent meta-information. */
@Bean(sortKeyes=#["name"])
interface MetaInfo extends Root {
	class Impl {
		// TODO This should be a virtual property
		/** Returns the qualified name (parent qualified name + own name) of this meta-info instance */
		static def String qualifiedName(EntityType it) {
			name
		}
	}
	/** All meta-info instance have the name of the code construct that they represent */
	String name
}

/** An Attribute type/descriptor. */
@Bean(instance=true)
interface AttributeType extends MetaInfo, Provider<Attribute> {
	class Impl {
		// TODO This should be a virtual property
		/** {@inheritDoc} */
		static def String qualifiedName(AttributeType it) {
			val parent = (it as _Bean).parent as EntityType
			if (parent == null) "?."+name else parent.name + "." + name
		}
		/** Pseudo-constructor for attribute types */
		static def void _init_(AttributeType it) {
			min = Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE
			max = Skills.DEFAULT_MAXIMUM_ATTRIBUTE_VALUE
			moreIsBetter = true
		}
		/** Creates a new Attribute */
		static def Attribute get(AttributeType it) {
			val result = Meta.ATTRIBUTE.create
			result.type = it
			result.baseValue = defaultValue
			result
		}
	}
	/** The default value of an Attribute of this type. */
	double defaultValue
	/** Allows explicitly clamping the value of an attribute to some minimum */
	double min
	/** Allows explicitly clamping the value of an attribute to some maximum */
	double max
	/** Are bigger values better? That decided if effects are buffs or debuffs. */
	boolean moreIsBetter
	/** Is this attribute a percent/probability (between 0.0 and 1.0?), or an "integer value" */
	boolean percent
	/** The category of the attribute. */
	AttributeCategory category
}

/** A Entity type/descriptor. */
@Bean(instance=true)
interface EntityType extends MetaInfo, Provider<Entity> {
	class Impl {
		/** Creates and adds a new attribute type, with default value, min, max, and non-percent */
		static def AttributeType newAttr(EntityType it,
			String name, AttributeCategory category) {
			newAttr(it, name, category, Skills.DEFAULT_ATTRIBUTE_VALUE,
				Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE,
				Skills.DEFAULT_MAXIMUM_ATTRIBUTE_VALUE, false)
		}
		/** Creates and adds a new non-percent attribute type */
		static def AttributeType newAttr(EntityType it,
			String name, AttributeCategory category, double defaultValue, double min, double max) {
			newAttr(it, name, category, defaultValue, min, max, false)
		}
		/** Creates and adds a new attribute type, with default min, and non-percent */
		static def AttributeType newAttr(EntityType it,
			String name, AttributeCategory category, double defaultValue, double max) {
			newAttr(it, name, category, defaultValue, Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE, max, false)
		}
		/** Creates and adds a new attribute type, with default value, min, and non-percent */
		static def AttributeType newAttr(EntityType it,
			String name, AttributeCategory category, double max) {
			newAttr(it, name, category, Skills.DEFAULT_ATTRIBUTE_VALUE, Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE, max, false)
		}
		/** Creates and adds a new auxiliary attribute type, with default value, min, max, and non-percent */
		static def AttributeType newAttr(EntityType it, String name) {
			newAttr(it, name, AttributeCategory.Auxiliary, Skills.DEFAULT_ATTRIBUTE_VALUE,
				Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE,
				Skills.DEFAULT_MAXIMUM_ATTRIBUTE_VALUE, false)
		}
		/** Creates and adds a new auxiliary non-percent attribute type */
		static def AttributeType newAttr(EntityType it, String name, double defaultValue, double min, double max) {
			newAttr(it, name, AttributeCategory.Auxiliary, defaultValue, min, max, false)
		}
		/** Creates and adds a new auxiliary attribute type, with default min, and non-percent */
		static def AttributeType newAttr(EntityType it, String name, double defaultValue, double max) {
			newAttr(it, name, AttributeCategory.Auxiliary, defaultValue, Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE, max, false)
		}
		/** Creates and adds a new auxiliary attribute type, with default value, min, and non-percent */
		static def AttributeType newAttr(EntityType it, String name, double max) {
			newAttr(it, name, AttributeCategory.Auxiliary, Skills.DEFAULT_ATTRIBUTE_VALUE, Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE, max, false)
		}
		/** Creates and adds a new auxiliary attribute type */
		static def AttributeType newAttr(EntityType it, String name, double defaultValue, double min, double max, boolean percent) {
			newAttr(it, name, AttributeCategory.Auxiliary, defaultValue, Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE, max, false)
		}
		/** Creates and adds a new attribute type, with default value, min, max, and percent */
		static def AttributeType newPercentAttr(EntityType it,
			String name, AttributeCategory category) {
			newAttr(it, name, category, Skills.DEFAULT_ATTRIBUTE_VALUE,
				Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE,
				Skills.DEFAULT_MAXIMUM_PERCENT_ATTRIBUTE_VALUE, true)
		}
		/** Creates and adds a new auxiliary attribute type, with default value, min, max, and percent */
		static def AttributeType newPercentAttr(EntityType it, String name) {
			newAttr(it, name, AttributeCategory.Auxiliary, Skills.DEFAULT_ATTRIBUTE_VALUE,
				Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE,
				Skills.DEFAULT_MAXIMUM_PERCENT_ATTRIBUTE_VALUE, true)
		}
		/** Creates and adds a new attribute type, with default value, min, max, and percent */
		static def AttributeType newPercentAttr(EntityType it,
			String name, AttributeCategory category, double defaultValue) {
			newAttr(it, name, category, defaultValue,
				Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE,
				Skills.DEFAULT_MAXIMUM_PERCENT_ATTRIBUTE_VALUE, true)
		}
		/** Creates and adds a new auxiliary attribute type, with default value, min, max, and percent */
		static def AttributeType newPercentAttr(EntityType it, String name, double defaultValue) {
			newAttr(it, name, AttributeCategory.Auxiliary, defaultValue,
				Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE,
				Skills.DEFAULT_MAXIMUM_PERCENT_ATTRIBUTE_VALUE, true)
		}
		/** Creates and adds a new attribute type */
		static def AttributeType newAttr(EntityType it, String name,
			AttributeCategory category, double defaultValue, double min, double max, boolean percent) {
			if (_attributes.containsKey(name)) {
				throw new IllegalArgumentException("AttributeType "+name+" already exists in "+it.name)
			}
			val result = Meta.ATTRIBUTE_TYPE.create
			result.name = name
			result.category = category
			result.defaultValue = defaultValue
			result.min = min
			result.max = max
			_attributes.put(result.name, result)
			result
		}
		/** Returns the attribute type with the given name, if any. */
		static def AttributeType attr(EntityType it,
			String name) {
			_attributes.get(name)
		}
		/** Creates a new Entity */
		static def Entity init(EntityType it, Entity entity) {
			entity._type = it
			for (at : _attributes.values) {
				entity._attributes.put(at.name, at.get)
			}
			entity
		}
		/** Creates a new Entity */
		static def Entity get(EntityType it) {
			init(Meta.ENTITY.create)
		}
		/** Pseudo-constructor for entity types */
		static def void _init_(EntityType it) {
			val simpleName = it.class.simpleName
			name = if (simpleName.endsWith("Impl"))
				simpleName.substring(0, simpleName.length-4)
			else
				simpleName
		}
	}
	/** The types of all the attributes of an entity */
	Map<String,AttributeType> _attributes
}

/** A System of Entity; all EntityTypes must be defined here. */
@Bean(instance=true)
interface EntitySystem extends MetaInfo {
	class Impl {
		/** Adds a new entity type to the system. */
		static def EntityType add(EntitySystem it, EntityType entityType) {
			val name = requireNonNull(entityType,  "entityType").name
			requireNonNull(name,  "entityType.name")
			if (_entityTypes.containsKey(name)) {
				throw new IllegalArgumentException("EntityType "+name+" already exists")
			}
			if (!entityType.immutable) {
				throw new IllegalArgumentException("EntityType "+name+" must be immutable")
			}
			_entityTypes.put(name, entityType)
			entityType
		}

		/** Lists all the entity types */
		static def Iterable<EntityType> list(EntitySystem it) {
			_entityTypes.values
		}

		/** Returns the entity type with the given name, or null. */
		static def EntityType find(EntitySystem it, String name) {
			_entityTypes.get(name)
		}
	}

	/** All the entity types in the system. */
	Map<String,EntityType> _entityTypes
}

/** An Attribute is simply a named Value. */
@Bean(instance=true)
interface Attribute extends Root {
	class Impl {
		/** Evaluates the effective value of an attribute of an entity. */
		static def double eval(Attribute it, Filter filter) {
			var result = baseValue
			for (e : _effects) {
				result = e.eval(filter, result)
			}
			val min = type.min
			val max = type.max
			if (result < min) {
				result = min
			}
			if (result > max) {
				result = max
			}
			result
		}

		/** Describes the evaluation of the effective value of an attribute of an entity. */
		static def String describe(Attribute it, Filter filter) {
			var result = "baseValue("+baseValue+")"
			for (e : _effects) {
				result = e.describe(filter, result)
			}
			val min = type.min
			val max = type.max
			if (min != Skills.DEFAULT_MINIMUM_ATTRIBUTE_VALUE) {
				result = "min("+result+","+min+")"
			}
			if (max != Skills.DEFAULT_MAXIMUM_ATTRIBUTE_VALUE) {
				result = "max("+result+","+max+")"
			}
			result
		}

		/** Adds one more effect to this attribute. */
		static def void operator_add(Attribute it, Effect newEffect) {
			val type = requireNonNull(requireNonNull(newEffect, "newEffect").type, "newEffect.type")
			val category = requireNonNull(type.category, "newEffect.type.category")
			val iter = _effects.iterator
			while (iter.hasNext) {
				val next = iter.next
				if (next.type.category == category) {
					iter.remove
				}
			}
			_effects.add(newEffect)
		}
	}
	/** The type of the attribute */
	AttributeType type
	/** The base value of the attribute */
	double baseValue
	/** All the effects that apply to the base value */
	Effect[] _effects
}

/** A Entity can have zero or more properties. */
interface Entity extends Root {
	class Impl {
		/** Returns the attribute with the given name, if any. */
		static def Attribute attr(Entity it, String name) {
			_attributes.get(name)
		}
		/** Returns the attribute with the given AttributeType, if any. */
		static def Attribute attr(Entity it, AttributeType attributeType) {
			val result = _attributes.get(attributeType.name)
			if ((result != null) && (result.type == attributeType)) result else null
		}
		/** The type of the entity */
		static def EntityType type(Entity it) {
			_type
		}
	}
	/** The type of the entity */
	EntityType _type
	/** The attributes of the entity */
	Map<String,Attribute> _attributes
}

/** The type of an effect. */
@Bean(instance=true)
interface EffectType extends EntityType {
	class Impl {
		/** Pseudo-constructor for basic effects */
		static def void _init_(EffectType it) {
			newPercentAttr("percentActivation", 1)
			newPercentAttr("percentPerTurn", 1)
			newAttr("duration", Skills.DEFAULT_DURATION_IN_TURN)
			category = EffectCategory.Simple
		}
		/** Creates a new Effect */
		static def Effect get(EffectType it) {
			init(Meta.EFFECT.create) as Effect
		}

		/**
		 * Probability of activation, in percent. If the check fails,
		 * the effect will not apply at all.
		 */
		static def AttributeType percentActivation(EffectType it) { attr("percentActivation") }

		/** Probability of activation *per turn*, in percent. */
		static def AttributeType percentPerTurn(EffectType it) { attr("percentPerTurn") }

		/** Duration of the effect, in turns. */
		static def AttributeType duration(EffectType it) { attr("duration") }
	}

	/** The category of an effect */
	EffectCategory category

	/**
	 * Does this effect adds up to the base stat as an absolute value (false)
	 * or instead as a percent (true)?
	 */
	boolean percent
}

/** An effect can modify a value */
interface Effect extends Entity {
	class Impl {
		/** Evaluates the effective value of an attribute of an entity. */
		static def double eval(Effect it, Filter filter, double previousValue) {
			if ((filter == null) || filter.accept(it)) _eval(previousValue) else previousValue
		}

		/** Describes the evaluation of the effective value of an attribute of an entity. */
		static def String describe(Effect it, Filter filter, String previousValue) {
			if ((filter == null) || filter.accept(it)) _describe(previousValue) else previousValue
		}
		/** Returns true if this Effect is "negative" (a debuff). */
		static def boolean debuff(Effect it) {
			!buff
		}
		/** The type of the entity */
		static def EffectType type(Effect it) {
			_type as EffectType
		}

		/**
		 * Probability of activation, in percent. If the check fails,
		 * the effect will not apply at all.
		 */
		static def Attribute percentActivation(Effect it) { attr("percentActivation") }

		/** Probability of activation *per turn*, in percent. */
		static def Attribute percentPerTurn(Effect it) { attr("percentPerTurn") }

		/** Duration of the effect, in turns. */
		static def Attribute duration(Effect it) { attr("duration") }
	}

	/** The turn on which the effect was created. */
	int creationTurn

	/** Evaluate self, based on the previous value. */
	def double _eval(double previousValue)
	/** Evaluate self, based on the previous description. */
	def String _describe(String previousValue)
	/** Returns true if this Effect is "positive" (a buff). */
	def boolean buff()
}

/**
 * The type of an effect.
 */
@Bean(instance=true)
interface BasicEffectType extends EffectType {
	class Impl {
		/** Pseudo-constructor for basic effects */
		static def void _init_(BasicEffectType it) {
			// We do not know yet if it's going to be a "percent" effect
			newAttr("effect")
		}
		/** Creates a new BasicEffect */
		static def BasicEffect get(BasicEffectType it) {
			init(Meta.BASIC_EFFECT.create) as BasicEffect
		}

		/** The value/strength of the "effect". */
		static def AttributeType effect(BasicEffectType it) { attr("effect") }
	}
}

/** A basic effect uses a standard algorithm to modify a value */
@Bean(instance=true)
interface BasicEffect extends Effect {
	class Impl {
		/** {@inheritDoc} */
		static def double _eval(BasicEffect it, double previousValue) {
			val change = effect.eval(null)
			if (type.percent) (previousValue * change) else (previousValue + change)
		}
		/** {@inheritDoc} */
		static def String _describe(BasicEffect it, String previousValue) {
			val change = effect.eval(null)
			previousValue + " + "+type.name+"("+if (type.percent)
				(change*100.0)+"%)"
			else
				change+")"
		}
		/** Returns true if this Effect is "positive" (a buff). */
		static def boolean buff(BasicEffect it) {
			if (type.percent) (effect.baseValue > 1) else (effect.baseValue > 0)
		}
		/** The type of the entity */
		static def BasicEffectType type(BasicEffect it) {
			_type as BasicEffectType
		}
		/** The value/strength of the "effect". */
		static def Attribute effect(BasicEffect it) { attr("effect") }
	}
}

/** Matches an attribute, to which an effect should be applied */
interface AttributeMatcher {
	/** Returns true, if the attribute matches */
	def boolean matches(Entity entity, Attribute attribute)
}

/** A pair of attribute matcher, and effect type, to create an effect, when appropriate */
@Data
class EffectBuilder {
	EffectType type
	AttributeMatcher matcher
}

/** The type of a modifier. */
@Bean(instance=true)
interface ModifierType extends EntityType {
	class Impl {
		/** Pseudo-constructor for basic effects */
		static def void _init_(ModifierType it) {
		}
		/** Creates and adds a new BasicEffect builder */
		static def EffectBuilder newBasicEffect(ModifierType it, String name,
			double percentActivation, double percentPerTurn, double duration,
			boolean percent, EffectCategory category, AttributeMatcher matcher) {
			requireNonNull(matcher, "matcher")
			val type = Meta.BASIC_EFFECT_TYPE.create
			type.percentActivation.defaultValue = percentActivation
			type.percentPerTurn.defaultValue = percentPerTurn
			type.duration.defaultValue = duration
			type.percent = percent
			type.category = category
			type.name = name
			val result = new EffectBuilder(type, matcher)
			builders.add(result)
			result
		}
		/** Creates a new Modifier */
		static def Modifier get(ModifierType it) {
			init(Meta.MODIFIER.create) as Modifier
		}
	}
	EffectBuilder[] builders
}

/** A modifier is an effect factory, representing the effects of one attack/skill/equipment/... */
interface Modifier extends Entity {
	class Impl {
		/** The type of the entity */
		static def ModifierType type(Modifier it) {
			_type as ModifierType
		}
	}
}

/** The type of a character. */
@Bean(instance=true)
interface CharacterType extends EntityType {
	class Impl {
		/** Pseudo-constructor for basic effects */
		static def void _init_(CharacterType it) {
			// TODO Use newPercentAttr() for percent/probability attributes
			newAttr("speed", AttributeCategory.Attack)
			newAttr("dexterity", AttributeCategory.Attack)
			newAttr("rage", AttributeCategory.Attack)
			newAttr("fury", AttributeCategory.Attack)
			newAttr("strength", AttributeCategory.Attack)
			newAttr("anima", AttributeCategory.Attack)

			newAttr("psyche", AttributeCategory.Defense)
			newAttr("defense", AttributeCategory.Defense)
			newAttr("reflex", AttributeCategory.Defense)
			newAttr("block", AttributeCategory.Defense)
			newAttr("constitution", AttributeCategory.Defense)
			newAttr("spirit", AttributeCategory.Defense)
			newAttr("harmony", AttributeCategory.Defense)

			newAttr("mana")
			newAttr("hp")
			newAttr("intelligence")
			newAttr("artistry")
			newAttr("level")
			newAttr("xp")
		}
		/** Creates a new Character */
		static def Character get(CharacterType it) {
			init(Meta.CHARACTER.create) as Character
		}
	}
}

/** Represents a Player character, so we have something to test against */
@Bean(instance=true)
interface Character extends Entity {
	class Impl {
		/** The type of the entity */
		static def CharacterType type(Character it) {
			_type as CharacterType
		}
		/** The attack rate. */
		static def Attribute speed(Character it) { attr("speed") }
		/** The spellpower. */
		static def Attribute mana(Character it) { attr("mana") }
		/** Hitpoints (life) */
		static def Attribute hp(Character it) { attr("hp") }
		/** Affects your ability to enchant items OR craft magical items such as potions or even scrolls */
		static def Attribute intelligence(Character it) { attr("intelligence") }
		/** Resistance to incoming magical attacks and mana growth */
		static def Attribute psyche(Character it) { attr("psyche") }
		/** Affects your ability to craft */
		static def Attribute artistry(Character it) { attr("artistry") }
		/** Resistance to incoming physical attacks and hp growth */
		static def Attribute defense(Character it) { attr("defense") }
		/** Chance to dodge incoming attacks */
		static def Attribute reflex(Character it) { attr("reflex") }
		/** Chance to block incoming attacks */
		static def Attribute block(Character it) { attr("block") }
		/** Chance to hit the opponent */
		static def Attribute dexterity(Character it) { attr("dexterity") }
		/** Chance to cause a critical hit */
		static def Attribute rage(Character it) { attr("rage") }
		/** % increase on critical hits. */
		static def Attribute fury(Character it) { attr("fury") }
		/** Resistance to poison and debuffs that affect damage taken */
		static def Attribute constitution(Character it) { attr("constitution") }
		/** Resistance to lifedrain and debuffs affecting your attack stats */
		static def Attribute spirit(Character it) { attr("spirit") }
		/** Affects the power of physical attacks */
		static def Attribute strength(Character it) { attr("strength") }
		/** Affects the power of magical attacks */
		static def Attribute anima(Character it) { attr("anima") }
		/** "the opposite of rage" : reduces chance to receive a critical hit from enemy */
		static def Attribute harmony(Character it) { attr("harmony") }
		/** The level (general power) of the character */
		static def Attribute level(Character it) { attr("level") }
		/** The earned experience points since starting the current level */
		static def Attribute xp(Character it) { attr("xp") }
	}

	/** The player name */
	String name
}

interface Skills {
	/** The entity system singleton */
	EntitySystem ENTITY_SYSTEM = Meta.ENTITY_SYSTEM.create

	/** The EffectType singleton */
	EffectType EFFECT_TYPE = ENTITY_SYSTEM.add(Meta.EFFECT_TYPE.create.snapshot) as EffectType

	/** The CharacterType singleton */
	CharacterType CHARACTER_TYPE = ENTITY_SYSTEM.add(Meta.CHARACTER_TYPE.create.snapshot) as CharacterType

	/** The default attribute value */
	double DEFAULT_ATTRIBUTE_VALUE = 0.0

	/** The default minimum attribute value */
	double DEFAULT_MINIMUM_ATTRIBUTE_VALUE = 0.0

	/** The default maximum attribute value */
	double DEFAULT_MAXIMUM_ATTRIBUTE_VALUE = 99_999.0

	/** The default maximum "percent" attribute value */
	double DEFAULT_MAXIMUM_PERCENT_ATTRIBUTE_VALUE = 100.0

	/** The default probability of activation */
	double DEFAULT_PROBABILITY_OF_ACTIVATION = 1.0

	/** The default probability per turn */
	double DEFAULT_PROBABILITY_PER_TURN = 1.0

	/** The default duration in turn */
	double DEFAULT_DURATION_IN_TURN = 999.0
}