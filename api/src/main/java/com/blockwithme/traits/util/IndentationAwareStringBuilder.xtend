package com.blockwithme.traits.util

import static extension com.google.common.base.Strings.*

class IndentationAwareStringBuilder {
		val builder = new StringBuilder()
		var indentation = 0
		static val indentationString = "  "
		static val newLineString = "\n"

		def increaseIndent() {
			indentation = indentation + 1
			return this
		}
		def decreaseIndent() {
			indentation = indentation - 1
			return this
		}
		def append(CharSequence string) {
			if (indentation>0) {
				val replacement = newLineString + indentationString.repeat(indentation)
				val indented = string.toString().replace(newLineString, replacement)
				builder.append(indented);
			} else {
				builder.append(string)
			}
			return this
		}
		def newLine() {
			builder.append(newLineString).append(indentationString.repeat(indentation))
			return this
		}
		override toString() {
			return builder.toString()
		}
	}
