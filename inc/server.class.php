<?php

/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 * Description of server
 *
 * @author Javier Samaniego García <jsamaniegog@gmail.com>
 */
class PluginDnsinventoryServer extends CommonDBTM {

    static $rightname = 'config';
    public $dohistory = false;

    //public $fields = array("address");

    static function getTypeName($nb = 0) {
        return _n('DNS Server', 'DNS Servers', $nb, 'dnsinventory');
    }

    /**
     * @return array
     */
    function getSearchOptions() {

        $tab = array();

        $tab['common'] = _n('DNS Server', 'DNS Servers', $nb, 'dnsinventory');

        $tab[1]['table'] = $this->getTable();
        $tab[1]['field'] = 'name';
        $tab[1]['name'] = __('DNS Server name');
        $tab[1]['datatype'] = 'itemlink';
        $tab[1]['itemlink_type'] = $this->getType();

        $tab[2]['table'] = $this->getTable();
        $tab[2]['field'] = 'address';
        $tab[2]['name'] = __('DNS Server Address');

        return $tab;
    }

    /**
     * Show DNS server form to add or edit.
     * @global type $DB
     * @param int $ID
     * @param array $options
     * @return boolean
     */
    function showForm($ID, array $options = []) {
        global $DB;

        if (!Session::haveRight("config", UPDATE)) {
            return false;
        }

        // get server data or prepare for new entry
        if ($ID > 0) {
            $this->getFromDB($ID);
        } else {
            $this->getEmpty();
        }

        $this->showFormHeader($options);

        // HTML
        // fields
        echo "<tr><td colspan='2'>";

        // hidden id
        echo "<input type='hidden' name='id' value='" . ($this->fields['id'] ?? 0) . "'>";

        echo __('Name') . "</td><td colspan='2'>";
        echo "<input type='text' name='name' value='" . htmlspecialchars($this->fields['name'] ?? '', ENT_QUOTES) . "' required='required' class='form-control'>";

        echo "</td></tr><tr><td colspan='2'>";

        echo __('Address', 'dnsinventory') . "</td><td colspan='2'>";
        echo "<input type='text' name='address' value='" . htmlspecialchars($this->fields['address'] ?? '', ENT_QUOTES) . "' required='required' class='form-control'>";

        echo "</td></tr>";


        $this->showFormButtons($options);

        return true;
    }
}
