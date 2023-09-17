/*   <Source Guard> (c) by <De Battista Clint - (https://sourcemod.market)   */
/*                                                                           */
/*                     <Source Guard> is licensed under a                    */
/*                        GNU General Public License                         */
/*																			 */
/*      You should have received a copy of the license along with this       */
/*            work.  If not, see <http://www.gnu.org/licenses/>.             */
//***************************************************************************//
//***************************************************************************//
//*******************************Source Guard********************************//
//***************************************************************************//
//***************************************************************************//

#if defined _SourceGuard_included
 #endinput
#endif
#define _SourceGuard_included

native void SourceGuard(char[] url);


public SharedPlugin __pl_SourceGuard =
{
	name = "SourceGuard",
	file = "SourceGuard.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_SourceGuard_SetNTVOptional()
{
	MarkNativeAsOptional("SourceGuard");
}
#endif